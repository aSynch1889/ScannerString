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
        List {
            // 扫描控制部分
            Section(header: Text("扫描控制").font(.headline)) {
                Button(action: viewModel.selectFolder) {
                    Label("选择文件夹", systemImage: "folder")
                }
                .buttonStyle(.plain)
                
                Button(action: viewModel.startScan) {
                    Label("开始扫描", systemImage: "magnifyingglass")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedPath.isEmpty)
                
                if viewModel.isScanning {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(.linear)
                }
            }
            
            // 扫描结果统计
            Section(header: Text("扫描统计").font(.headline)) {
                HStack {
                    Image(systemName: "text.quote")
                    Text("字符串数量")
                    Spacer()
                    Text("\(viewModel.results.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "doc.text")
                    Text("文件数量")
                    Spacer()
                    Text("\(Set(viewModel.results.map { $0.file }).count)")
                        .foregroundColor(.secondary)
                }
            }
            
            // 导出选项
            Section(header: Text("导出选项").font(.headline)) {
                Button(action: viewModel.exportToJSON) {
                    Label("导出为 JSON", systemImage: "doc.text")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.results.isEmpty)
                
                Button(action: viewModel.exportToCSV) {
                    Label("导出为 CSV", systemImage: "tablecells")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.results.isEmpty)
                
                Button(action: viewModel.exportToLocalizationFiles) {
                    Label("导出本地化文件", systemImage: "globe")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.results.isEmpty)
                
                Button(action: viewModel.exportToXCStrings) {
                    Label("导出 XCStrings", systemImage: "doc.text.fill")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.results.isEmpty)
            }
            
            // 项目信息
            Section(header: Text("项目信息").font(.headline)) {
                if !viewModel.selectedPath.isEmpty {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("当前项目")
                        Spacer()
                        Text(viewModel.selectedPath)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 250)
        .id(viewModel.languageChanged)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            viewModel.languageChanged.toggle()
        }
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
                    HStack {
                        Spacer()
                        
                        Button(action: viewModel.exportToJSON) {
                            Label("Export JSON".localized, systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToCSV) {
                            Label("Export CSV".localized, systemImage: "tablecells")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToLocalizationFiles) {
                            Label("Export Strings".localized, systemImage: "text.quote")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.exportToXCStrings) {
                            Label("Export XCStrings".localized, systemImage: "globe")
                        }
                        .buttonStyle(.bordered)
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
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
