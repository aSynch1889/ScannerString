import SwiftUI

struct FilterControlPanel: View {
    @ObservedObject var viewModel: ScannerViewModel
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 过滤器标题栏
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                Text("字符串过滤器".localized)
                    .font(.headline)
                    .font(.system(size: 14))

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(spacing: 12) {
                    // 过滤器总开关
                    HStack {
                        Toggle("启用过滤器".localized, isOn: Binding(
                            get: { viewModel.filterEnabled },
                            set: { newValue in
                                viewModel.filterEnabled = newValue
                                viewModel.updateFilterManager()
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        Spacer()

                        if let filterResult = viewModel.filterResult {
                            Text("\(filterResult.filteredCount)/\(filterResult.originalCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if viewModel.filterEnabled {
                        Divider()

                        // 语言过滤器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("语言类型".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(DetectedLanguage.allCases, id: \.self) { language in
                                    HStack {
                                        Button(action: {
                                            toggleLanguage(language)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: viewModel.selectedLanguages.contains(language) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(viewModel.selectedLanguages.contains(language) ? .accentColor : .secondary)
                                                    .font(.system(size: 12))

                                                Text(language.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        Spacer()
                                    }
                                }
                            }
                        }

                        Divider()

                        // 长度过滤器
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("最小长度".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                Text("\(viewModel.minStringLength)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.minStringLength) },
                                    set: { viewModel.minStringLength = Int($0) }
                                ),
                                in: 1...20,
                                step: 1
                            ) {
                                Text("最小长度")
                            } onEditingChanged: { editing in
                                if !editing {
                                    viewModel.updateFilterManager()
                                }
                            }
                            .controlSize(.small)
                        }

                        Divider()

                        // 内容过滤器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("内容过滤".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            VStack(spacing: 6) {
                                HStack {
                                    Toggle("排除空字符串".localized, isOn: Binding(
                                        get: { viewModel.excludeEmptyStrings },
                                        set: { newValue in
                                            viewModel.excludeEmptyStrings = newValue
                                            viewModel.updateFilterManager()
                                        }
                                    ))
                                    .controlSize(.small)
                                    .font(.caption)

                                    Spacer()
                                }

                                HStack {
                                    Toggle("排除纯数字".localized, isOn: Binding(
                                        get: { viewModel.excludeNumericOnly },
                                        set: { newValue in
                                            viewModel.excludeNumericOnly = newValue
                                            viewModel.updateFilterManager()
                                        }
                                    ))
                                    .controlSize(.small)
                                    .font(.caption)

                                    Spacer()
                                }

                                HStack {
                                    Toggle("排除重复字符串".localized, isOn: Binding(
                                        get: { viewModel.excludeDuplicates },
                                        set: { newValue in
                                            viewModel.excludeDuplicates = newValue
                                            viewModel.updateFilterManager()
                                        }
                                    ))
                                    .controlSize(.small)
                                    .font(.caption)

                                    Spacer()
                                }
                            }
                        }

                        Divider()

                        // 预设配置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("快速配置".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                Button("基础".localized) {
                                    applyBasicFilter()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("严格".localized) {
                                    applyStrictFilter()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("本地化".localized) {
                                    applyLocalizationFilter()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button("重置".localized) {
                                    resetFilters()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        // 过滤统计信息
                        if let filterResult = viewModel.filterResult {
                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("过滤统计".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                HStack {
                                    Text("原始数量:".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(filterResult.originalCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)

                                    Spacer()

                                    Text("过滤后:".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(filterResult.filteredCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.accentColor)
                                }

                                HStack {
                                    Text("过滤率:".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(String(format: "%.1f", filterResult.filterRatio * 100))%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)

                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }

    private func toggleLanguage(_ language: DetectedLanguage) {
        if viewModel.selectedLanguages.contains(language) {
            viewModel.selectedLanguages.remove(language)
        } else {
            viewModel.selectedLanguages.insert(language)
        }
        viewModel.updateFilterManager()
    }

    private func applyBasicFilter() {
        viewModel.filterEnabled = true
        viewModel.selectedLanguages = [.chinese, .english, .mixed]
        viewModel.minStringLength = 2
        viewModel.excludeEmptyStrings = true
        viewModel.excludeNumericOnly = false
        viewModel.excludeDuplicates = false
        viewModel.updateFilterManager()
    }

    private func applyStrictFilter() {
        viewModel.filterEnabled = true
        viewModel.selectedLanguages = [.chinese, .english, .mixed]
        viewModel.minStringLength = 3
        viewModel.excludeEmptyStrings = true
        viewModel.excludeNumericOnly = true
        viewModel.excludeDuplicates = true
        viewModel.updateFilterManager()
    }

    private func applyLocalizationFilter() {
        viewModel.filterEnabled = true
        viewModel.selectedLanguages = [.chinese, .mixed]
        viewModel.minStringLength = 1
        viewModel.excludeEmptyStrings = true
        viewModel.excludeNumericOnly = false
        viewModel.excludeDuplicates = false
        viewModel.updateFilterManager()
    }

    private func resetFilters() {
        viewModel.filterEnabled = true
        viewModel.selectedLanguages = Set(DetectedLanguage.allCases)
        viewModel.minStringLength = 1
        viewModel.excludeEmptyStrings = true
        viewModel.excludeNumericOnly = false
        viewModel.excludeDuplicates = false
        viewModel.updateFilterManager()
    }
}