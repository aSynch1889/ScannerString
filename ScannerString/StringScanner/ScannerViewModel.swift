import Foundation
import SwiftUI
import SwiftSyntax
import SwiftParser
import SwiftOperators

class ScannerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var results: [StringLocation] = []
    @Published var selectedPath: String = ""
    @Published var errorMessage: String?
    @Published var languageChanged = false
    @Published var currentFile: String = ""
    @Published var processedFiles: Int = 0
    @Published var totalFiles: Int = 0

    // 过滤器相关属性
    @Published var filterEnabled = true
    @Published var selectedLanguages: Set<DetectedLanguage> = [.chinese, .english, .mixed]
    @Published var excludeDuplicates = false
    @Published var minStringLength = 1
    @Published var excludeEmptyStrings = true
    @Published var excludeNumericOnly = false
    @Published var filterResult: FilterResult?
    @Published var rawResults: [StringLocation] = []

    private let scanner: ProjectScanner
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "result.queue", attributes: .concurrent)
    private var allStrings: [StringLocation] = []
    private var filterManager = FilterManager()

    init() {
        scanner = ProjectScanner()
        updateFilterManager()
    }

    // 更新过滤器管理器
    func updateFilterManager() {
        filterManager.clearFilters()

        if filterEnabled {
            // 添加内容过滤器
            let contentFilter = ContentFilter(
                minLength: minStringLength,
                excludeEmpty: excludeEmptyStrings,
                excludeNumericOnly: excludeNumericOnly
            )
            filterManager.addFilter(contentFilter)

            // 添加语言过滤器
            if !selectedLanguages.isEmpty {
                let languageFilter = LanguageFilter(targetLanguages: selectedLanguages)
                filterManager.addFilter(languageFilter)
            }

            // 添加重复过滤器
            if excludeDuplicates {
                let duplicateFilter = DuplicateFilter(excludeDuplicates: true)
                filterManager.addFilter(duplicateFilter)
            }
        }

        scanner.setFilterManager(filterManager)
        applyCurrentFilters()
    }

    // 应用当前过滤器到结果
    func applyCurrentFilters() {
        guard !rawResults.isEmpty else { return }

        if filterEnabled {
            let filterResult = filterManager.applyFilters(to: rawResults)
            self.filterResult = filterResult
            self.results = filterResult.filteredResults
        } else {
            self.results = rawResults
            self.filterResult = nil
        }
    }
    
    func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                selectedPath = url.path
            }
        }
    }
    
    func handleDroppedFolder(_ url: URL) {
        // 检查是否是文件夹
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            selectedPath = url.path
        } else {
            errorMessage = "drag_folder_not_file".localized
        }
    }
    
    func startScan() {
        guard !selectedPath.isEmpty else {
            errorMessage = "Please select a folder first"
            return
        }
        
        isScanning = true
        progress = 0
        results = []
        allStrings = []
        currentFile = ""
        processedFiles = 0
        totalFiles = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.scanProject(at: self?.selectedPath ?? "")
        }
    }
    
    private func scanProject(at path: String) {
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            DispatchQueue.main.async {
                self.errorMessage = "Cannot enumerate directory contents"
                self.isScanning = false
            }
            return
        }
        
        let files = enumerator.compactMap { $0 as? URL }
            .filter { isValidFile($0) }
        
        DispatchQueue.main.async {
            self.totalFiles = files.count
        }
        
        DispatchQueue.concurrentPerform(iterations: files.count) { index in
            let file = files[index]
            DispatchQueue.main.async {
                self.currentFile = file.lastPathComponent
            }
            
            do {
                try self.scanFile(at: file)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error scanning \(file.path): \(error)"
                }
            }
            
            DispatchQueue.main.async {
                self.processedFiles += 1
                self.progress = Double(self.processedFiles) / Double(self.totalFiles)
            }
        }
        
        DispatchQueue.main.async {
            self.outputResults()
            self.isScanning = false
            self.currentFile = ""
        }
    }
    
    private func isValidFile(_ url: URL) -> Bool {
        let validExtensions = ["swift", "m", "h"]
        guard validExtensions.contains(url.pathExtension) else { return false }
        
        let excludedPaths = [
            "/Pods/", "/Carthage/", "/.swiftpm/",
            "/Tests/", "/Test/", "/Specs/",
            "/DerivedData/", "/build/"
        ]
        
        let path = url.path
        return !excludedPaths.contains { path.contains($0) }
    }
    
    private func scanFile(at url: URL) throws {
        let source = try String(contentsOf: url)
        let sourceFile = try Parser.parse(source: source)
        
        let operatorTable = OperatorTable.standardOperators
        let foldedFile = try operatorTable.foldAll(sourceFile)
        
        let locationConverter = SourceLocationConverter(
            fileName: url.path,
            tree: foldedFile
        )
        
        let visitor = StringVisitor(
            filePath: url.path,
            locationConverter: locationConverter
        )
        
        visitor.walk(foldedFile)
        
        queue.async(flags: .barrier) {
            self.allStrings.append(contentsOf: visitor.strings)
        }
    }
    
    private func outputResults() {
        rawResults = allStrings.sorted {
            $0.file == $1.file ?
                ($0.line == $1.line ? $0.column < $1.column : $0.line < $1.line) :
                $0.file < $1.file
        }
        applyCurrentFilters()
    }
    
    func exportToJSON() {
        guard !results.isEmpty else {
            errorMessage = "No results to export"
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "strings.json"
        savePanel.allowedContentTypes = [.json]
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(results)
                try data.write(to: url)
            } catch {
                errorMessage = "Failed to export JSON: \(error.localizedDescription)"
            }
        }
    }
    
    func exportToCSV() {
        guard !results.isEmpty else {
            errorMessage = "No results to export"
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "strings.csv"
        savePanel.allowedContentTypes = [.commaSeparatedText]
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            
            do {
                var csvString = "String,File,Line,Column,Is Localized\n"
                
                for result in results {
                    let escapedContent = result.content.replacingOccurrences(of: "\"", with: "\"\"")
                    let escapedFile = result.file.replacingOccurrences(of: "\"", with: "\"\"")
                    
                    csvString += "\"\(escapedContent)\",\"\(escapedFile)\",\(result.line),\(result.column),\"\(result.isLocalized ? "Yes" : "No")\"\n"
                }
                
                try csvString.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                errorMessage = "Failed to export CSV: \(error.localizedDescription)"
            }
        }
    }
    
    func exportToLocalizationFiles() {
        guard !results.isEmpty else {
            errorMessage = "No results to export"
            return
        }
        
        let savePanel = NSOpenPanel()
        savePanel.canChooseFiles = false
        savePanel.canChooseDirectories = true
        savePanel.allowsMultipleSelection = false
        savePanel.prompt = "Select Output Directory"
        
        if savePanel.runModal() == .OK {
            guard let outputURL = savePanel.url else { return }
            
            do {
                // 创建基础目录结构
                let baseURL = outputURL.appendingPathComponent("Localization")
                try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
                
                // 只生成当前语言的文件
                let languageURL = baseURL.appendingPathComponent("en.lproj")
                try FileManager.default.createDirectory(at: languageURL, withIntermediateDirectories: true)
                
                // 生成 .strings 文件
                let stringsURL = languageURL.appendingPathComponent("Localizable.strings")
                var stringsContent = ""
                
                for result in results {
                    // 转义字符串中的特殊字符
                    let escapedContent = result.content
                        .replacingOccurrences(of: "\"", with: "\\\"")
                        .replacingOccurrences(of: "\n", with: "\\n")
                    
                    // 使用字符串内容作为 key 和值
                    stringsContent += "\"\(escapedContent)\" = \"\(escapedContent)\";\n"
                }
                
                // 确保文件不为空
                if stringsContent.isEmpty {
                    stringsContent = "/* No localized strings found */\n"
                }
                
                // 写入文件
                try stringsContent.write(to: stringsURL, atomically: true, encoding: .utf8)
                
                // 显示成功消息
                DispatchQueue.main.async {
                    self.errorMessage = "Localization files generated successfully at: \(baseURL.path)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate localization files: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func exportToXCStrings() {
        guard !results.isEmpty else {
            errorMessage = "No results to export"
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "xcstrings")!]
        savePanel.nameFieldStringValue = "Localizable.xcstrings"
        
        if savePanel.runModal() == .OK {
            guard let outputURL = savePanel.url else { return }
            
            do {
                var xcstringsContent = """
                {
                  "sourceLanguage" : "en",
                  "strings" : {
                """
                
                for (index, result) in results.enumerated() {
                    // 转义字符串中的特殊字符
                    let escapedContent = result.content
                        .replacingOccurrences(of: "\"", with: "\\\"")
                        .replacingOccurrences(of: "\n", with: "\\n")
                    
                    xcstringsContent += """
                    
                        "\(escapedContent)" : {
                          "extractionState" : "manual",
                          "localizations" : {
                            "en" : {
                              "stringUnit" : {
                                "state" : "translated",
                                "value" : "\(escapedContent)"
                              }
                            }
                          }
                        }\(index < results.count - 1 ? "," : "")
                    """
                }
                
                xcstringsContent += """
                
                  },
                  "version" : "1.0"
                }
                """
                
                // 确保文件不为空
                if results.isEmpty {
                    xcstringsContent = """
                    {
                      "sourceLanguage" : "en",
                      "strings" : {
                        "NO_STRINGS" : {
                          "extractionState" : "manual",
                          "localizations" : {
                            "en" : {
                              "stringUnit" : {
                                "state" : "translated",
                                "value" : "No localized strings found"
                              }
                            }
                          }
                        }
                      },
                      "version" : "1.0"
                    }
                    """
                }
                
                // 写入文件
                try xcstringsContent.write(to: outputURL, atomically: true, encoding: .utf8)
                
                // 显示成功消息
                DispatchQueue.main.async {
                    self.errorMessage = "XCStrings file generated successfully at: \(outputURL.path)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate XCStrings file: \(error.localizedDescription)"
                }
            }
        }
    }
} 
