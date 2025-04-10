import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            ResultsView(viewModel: viewModel)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 标题
                VStack(alignment: .leading, spacing: 2) {
                    Text("String Scanner".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("扫描项目中的字符串".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // 扫描控制卡片
                CardView(title: "扫描控制".localized, icon: "magnifyingglass") {
                    VStack(spacing: 8) {
                        Button(action: viewModel.selectFolder) {
                            HStack {
                                Image(systemName: "folder")
                                Text("选择文件夹".localized)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: viewModel.startScan) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("开始扫描".localized)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(viewModel.selectedPath.isEmpty ? Color.secondary.opacity(0.1) : Color.blue.opacity(0.1))
                            .foregroundColor(viewModel.selectedPath.isEmpty ? .secondary : .blue)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.selectedPath.isEmpty)
                        
                        if viewModel.isScanning {
                            ProgressView(value: viewModel.progress)
                                .progressViewStyle(.linear)
                                .tint(.blue)
                        }
                    }
                }
                
                // 扫描统计卡片
                CardView(title: "扫描统计".localized, icon: "chart.bar") {
                    VStack(spacing: 8) {
                        StatItem(icon: "text.quote", title: "字符串数量".localized, value: "\(viewModel.results.count)")
                        StatItem(icon: "doc.text", title: "文件数量".localized, value: "\(Set(viewModel.results.map { $0.file }).count)")
                    }
                }
                
                // 导出选项卡片
                CardView(title: "导出选项".localized, icon: "square.and.arrow.down") {
                    VStack(spacing: 8) {
                        ExportButton(title: "导出为 JSON".localized, icon: "doc.text", action: viewModel.exportToJSON, isDisabled: viewModel.results.isEmpty)
                        ExportButton(title: "导出为 CSV".localized, icon: "tablecells", action: viewModel.exportToCSV, isDisabled: viewModel.results.isEmpty)
                        ExportButton(title: "导出本地化文件".localized, icon: "globe", action: viewModel.exportToLocalizationFiles, isDisabled: viewModel.results.isEmpty)
                        ExportButton(title: "导出 XCStrings".localized, icon: "doc.text.fill", action: viewModel.exportToXCStrings, isDisabled: viewModel.results.isEmpty)
                    }
                }
                
                // 项目信息卡片
                if !viewModel.selectedPath.isEmpty {
                    CardView(title: "项目信息".localized, icon: "folder.fill") {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(viewModel.selectedPath)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(minWidth: 260)
        .id(viewModel.languageChanged)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            viewModel.languageChanged.toggle()
        }
    }
}

// 卡片视图组件
struct CardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text(title)
                    .font(.headline)
                    .font(.system(size: 14))
            }
            
            content
        }
        .padding(10)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// 统计项组件
struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 14))
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}

// 导出按钮组件
struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14))
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isDisabled ? Color.secondary.opacity(0.1) : Color.blue.opacity(0.1))
            .foregroundColor(isDisabled ? .secondary : .blue)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        VStack {
            if viewModel.results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Results".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Select a project folder to scan for strings".localized)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
//                    HStack {
//                        Spacer()
//                        
//                        Button(action: viewModel.exportToJSON) {
//                            Label("Export JSON".localized, systemImage: "square.and.arrow.down")
//                        }
//                        .buttonStyle(.bordered)
//                        
//                        Button(action: viewModel.exportToCSV) {
//                            Label("Export CSV".localized, systemImage: "tablecells")
//                        }
//                        .buttonStyle(.bordered)
//                        
//                        Button(action: viewModel.exportToLocalizationFiles) {
//                            Label("Export Strings".localized, systemImage: "text.quote")
//                        }
//                        .buttonStyle(.bordered)
//                        
//                        Button(action: viewModel.exportToXCStrings) {
//                            Label("Export XCStrings".localized, systemImage: "globe")
//                        }
//                        .buttonStyle(.bordered)
//                        .padding(.trailing)
//                    }
//                    .padding(.top)
                    
                    List(viewModel.results, id: \.self) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.content)
                                .font(.body)
                            
                            HStack {
                                Text(result.file)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Line \(result.line)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if result.isLocalized {
                                    Text("Localized".localized)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(minWidth: 500)
    }
}

#Preview {
    ContentView()
}
