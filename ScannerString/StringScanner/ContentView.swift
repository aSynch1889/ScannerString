import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    // @StateObject private var storeManager = StoreManager.shared
    @StateObject private var usageManager = UsageManager.shared
    @State private var isSidebarVisible = true
    // @State private var showingSubscriptionSheet = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: {
                            isSidebarVisible.toggle()
                        }) {
                            Image(systemName: "sidebar.left")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    // ToolbarItem(placement: .primaryAction) {
                    //     Button(action: {
                    //         showingSubscriptionSheet = true
                    //     }) {
                    //         Image(systemName: storeManager.hasUnlimitedSubscription ? "crown.fill" : "crown")
                    //             .foregroundColor(storeManager.hasUnlimitedSubscription ? .yellow : .accentColor)
                    //     }
                    // }
                }
        } detail: {
            ResultsView(viewModel: viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        // .sheet(isPresented: $showingSubscriptionSheet) {
        //     SubscriptionView()
        //         .presentationDetents([.height(500)])
        //         .presentationDragIndicator(.visible)
        // }
        // .task {
        //     await storeManager.start()
        // }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @ObservedObject var usageManager = UsageManager.shared
    
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
                        // 合并的选择区域
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            
                            if viewModel.selectedPath.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.accentColor)
                                    Text("点击或拖拽文件夹到此处".localized)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 16)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.accentColor)
                                    Text(URL(fileURLWithPath: viewModel.selectedPath).lastPathComponent)
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Text(viewModel.selectedPath)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        .onTapGesture {
                            viewModel.selectFolder()
                        }
                        .onDrop(of: [.fileURL], isTargeted: nil) { providers -> Bool in
                            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { data, error in
                                if let data = data,
                                   let path = String(data: data, encoding: .utf8),
                                   let url = URL(string: path) {
                                    DispatchQueue.main.async {
                                        viewModel.handleDroppedFolder(url)
                                    }
                                }
                            })
                            return true
                        }
                        
                        Button(action: {
                            // 移除使用次数限制，直接执行扫描
                            viewModel.startScan()
                            // usageManager.recordScan()  // 不再记录使用次数
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.accentColor)
                                Text("开始扫描".localized)
                                    .foregroundColor(.accentColor)
                                Spacer()
                                // 移除剩余次数显示
                                // if !usageManager.canPerformScan() {
                                //     Text("\(usageManager.remainingScansToday()) 次剩余".localized)
                                //         .font(.caption)
                                //         .foregroundColor(.secondary)
                                // }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.accentColor.opacity(0.1))  // 始终可用状态
                            .foregroundColor(.blue)  // 始终可用颜色
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        // .disabled(!usageManager.canPerformScan())  // 移除禁用逻辑
                        
                        if viewModel.isScanning {
                            VStack(spacing: 8) {
                                ProgressView(value: viewModel.progress)
                                    .progressViewStyle(.linear)
                                    .accentColor(.accentColor)
                                
                                HStack {
                                    Text("\(viewModel.processedFiles)/\(viewModel.totalFiles) 文件".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(viewModel.progress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !viewModel.currentFile.isEmpty {
                                    Text("正在扫描: \(viewModel.currentFile)".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                    }
                }
                
                // 扫描统计卡片
                CardView(title: "扫描统计".localized, icon: "chart.bar") {
                    VStack(spacing: 8) {
                        StatItem(icon: "text.quote", title: "string_count".localized, value: "\(viewModel.results.count)")
                        StatItem(icon: "doc.text", title: "file_count".localized, value: "\(Set(viewModel.results.map { $0.file }).count)")
                    }
                }
                
                // 过滤器控制面板
                FilterControlPanel(viewModel: viewModel)

                // 导出选项卡片
                CardView(title: "export_options".localized, icon: "square.and.arrow.down") {
                    VStack(spacing: 8) {
                        ExportButton(title: "export_as_json".localized, icon: "doc.text", action: viewModel.exportToJSON, isDisabled: viewModel.results.isEmpty)
                        ExportButton(title: "export_as_csv".localized, icon: "tablecells", action: viewModel.exportToCSV, isDisabled: viewModel.results.isEmpty)
                        ExportButton(title: "export_localization_files".localized, icon: "globe", action: viewModel.exportToLocalizationFiles, isDisabled: viewModel.results.isEmpty)
                        ExportButton(title: "export_xcstrings".localized, icon: "doc.text.fill", action: viewModel.exportToXCStrings, isDisabled: viewModel.results.isEmpty)
                    }
                }
                
                // 项目信息卡片
                if !viewModel.selectedPath.isEmpty {
                    CardView(title: "project_info".localized, icon: "folder.fill") {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.accentColor)
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
                    .foregroundColor(.accentColor)
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
                .foregroundColor(.accentColor)
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
            .background(isDisabled ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.1))
            .foregroundColor(isDisabled ? .secondary : .accentColor)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @State private var searchText = ""
    @State private var selectedTab = 0

    var filteredResults: [StringLocation] {
        if searchText.isEmpty {
            return viewModel.results
        } else {
            return viewModel.results.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.file.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.results.isEmpty && viewModel.rawResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    Text("No Results".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Select a project folder to scan for strings".localized)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // 顶部工具栏
                    HStack {
                        // 搜索框
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))

                            TextField("搜索字符串...".localized, text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)

                        Spacer()

                        // 结果统计
                        if !searchText.isEmpty {
                            Text("找到 \(filteredResults.count) 项".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let filterResult = viewModel.filterResult {
                            Text("\(filterResult.filteredCount)/\(filterResult.originalCount) 项".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))

                    Divider()

                    // 标签页选择器
                    Picker("view".localized, selection: $selectedTab) {
                        Text("string_list".localized).tag(0)
                        Text("language_distribution".localized).tag(1)
                        Text("filter_statistics".localized).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Divider()

                    // 内容区域
                    Group {
                        switch selectedTab {
                        case 0:
                            StringListView(results: filteredResults)
                        case 1:
                            LanguageDistributionView(results: viewModel.results)
                        case 2:
                            FilterStatisticsView(viewModel: viewModel)
                        default:
                            StringListView(results: filteredResults)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500)
    }
}

// 字符串列表视图
struct StringListView: View {
    let results: [StringLocation]

    var body: some View {
        List(results, id: \.self) { result in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.content)
                        .font(.body)
                        .lineLimit(2)

                    Spacer()

                    // 语言标签
                    Text(result.detectedLanguage.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(languageColor(result.detectedLanguage))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }

                HStack {
                    Text(URL(fileURLWithPath: result.file).lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.accentColor)

                    Text("Line \(result.line):\(result.column)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if result.isLocalized {
                        Text("Localization".localized)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    // 内容类型标签
                    if result.contentType != .normal {
                        Text(result.contentType.displayName)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    Text("\(result.content.count) 字符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func languageColor(_ language: DetectedLanguage) -> Color {
        switch language {
        case .chinese: return .red
        case .english: return .blue
        case .mixed: return .purple
        case .numeric: return .orange
        case .symbolic: return .gray
        case .unknown: return .secondary
        }
    }
}

// 语言分布视图
struct LanguageDistributionView: View {
    let results: [StringLocation]

    private var languageStats: [(DetectedLanguage, Int)] {
        var counts: [DetectedLanguage: Int] = [:]
        for result in results {
            counts[result.detectedLanguage, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !results.isEmpty {
                    ForEach(languageStats, id: \.0) { language, count in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(language.displayName)
                                    .font(.headline)

                                Spacer()

                                Text("\(count) 项")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("(\(String(format: "%.1f", Double(count) / Double(results.count) * 100))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            ProgressView(value: Double(count), total: Double(results.count))
                                .progressViewStyle(.linear)
                                .accentColor(languageColor(language))
                        }
                        .padding(.horizontal, 16)
                    }
                } else {
                    Text("暂无数据".localized)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func languageColor(_ language: DetectedLanguage) -> Color {
        switch language {
        case .chinese: return .red
        case .english: return .blue
        case .mixed: return .purple
        case .numeric: return .orange
        case .symbolic: return .gray
        case .unknown: return .secondary
        }
    }
}

// 过滤统计视图
struct FilterStatisticsView: View {
    @ObservedObject var viewModel: ScannerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let filterResult = viewModel.filterResult {
                    // 过滤概览
                    VStack(alignment: .leading, spacing: 12) {
                        Text("filter_overview".localized)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            StatCard(title: "original_count_label".localized, value: "\(filterResult.originalCount)", color: .secondary)
                            StatCard(title: "filtered_label".localized, value: "\(filterResult.filteredCount)", color: .accentColor)
                            StatCard(title: "filter_rate_label".localized, value: "\(String(format: "%.1f%%", filterResult.filterRatio * 100))", color: .orange)
                        }
                    }

                    // 过滤步骤
                    if !filterResult.filterSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("filter_steps".localized)
                                .font(.title2)
                                .fontWeight(.bold)

                            ForEach(Array(filterResult.filterSteps.enumerated()), id: \.offset) { index, step in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(index + 1). \(step.filterName)")
                                            .font(.headline)

                                        Spacer()

                                        Text("\(step.beforeCount) → \(step.afterCount)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(step.filterDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Text("移除: \(step.filteredCount) 项")
                                            .font(.caption)

                                        Text("(\(String(format: "%.1f%%", step.filterRatio * 100)))")
                                            .font(.caption)
                                            .foregroundColor(.orange)

                                        Spacer()

                                        Text("耗时: \(String(format: "%.3f", step.duration))秒")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    ProgressView(value: Double(step.filteredCount), total: Double(step.beforeCount))
                                        .progressViewStyle(.linear)
                                        .accentColor(.orange)
                                }
                                .padding(12)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                } else {
                    Text("no_filter_statistics".localized)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(16)
        }
    }
}

// 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
