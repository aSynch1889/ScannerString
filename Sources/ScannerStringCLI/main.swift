import Foundation
import ArgumentParser
import ScannerString

@main
struct ScannerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scannerstring",
        abstract: "A command-line tool for scanning and filtering strings in Swift projects.",
        version: "1.0.0"
    )

    @Argument(help: "The project path to scan")
    var projectPath: String

    @Option(name: .shortAndLong, help: "Output format (json, csv, text)")
    var format: OutputFormat = .json

    @Option(name: .shortAndLong, help: "Configuration file path")
    var config: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Languages to include (chinese, english, mixed, numeric, unknown)")
    var languages: [String] = []

    @Option(name: .long, help: "Minimum string length")
    var minLength: Int = 1

    @Flag(name: .long, help: "Exclude duplicate strings")
    var excludeDuplicates: Bool = false

    @Flag(name: .long, help: "Exclude empty strings")
    var excludeEmpty: Bool = false

    @Flag(name: .long, help: "Exclude numeric-only strings")
    var excludeNumeric: Bool = false

    @Flag(name: .long, help: "Show filter statistics")
    var showStats: Bool = false

    @Option(name: .shortAndLong, help: "Output file path (default: stdout)")
    var output: String?

    mutating func run() async throws {
        print("🔍 Scanning project at: \(projectPath)")

        // Load configuration if provided
        var filterConfig = FilterConfiguration()
        if let configPath = config {
            filterConfig = try loadConfiguration(from: configPath)
        }

        // Override with command line parameters
        applyCommandLineOptions(to: &filterConfig)

        // Initialize scanner with filter manager
        let filterManager = FilterManager()
        configureFilters(filterManager: filterManager, config: filterConfig)

        let scanner = ProjectScanner(filterManager: filterManager)
        scanner.scanProject(at: projectPath)
        let rawResults = scanner.getRawScanResults()
        let filterResult = scanner.getScanResultsWithFilterInfo()

        if showStats && filterResult != nil {
            printStatistics(filterResult: filterResult!)
        }

        // Generate output
        let results = filterResult?.filteredResults ?? rawResults
        let outputData = try generateOutput(
            results: results,
            format: format,
            includeStats: showStats,
            filterResult: filterResult
        )

        // Write output
        if let outputPath = output {
            try outputData.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: String.Encoding.utf8)
            print("✅ Results written to: \(outputPath)")
        } else {
            print(outputData)
        }
    }

    private func loadConfiguration(from path: String) throws -> FilterConfiguration {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)

        if path.hasSuffix(".json") {
            return try JSONDecoder().decode(FilterConfiguration.self, from: data)
        } else if path.hasSuffix(".yml") || path.hasSuffix(".yaml") {
            // For now, we'll support JSON format only
            // YAML support could be added with a third-party library
            throw CLIError.unsupportedConfigFormat("YAML support not implemented yet. Please use JSON format.")
        }

        throw CLIError.unsupportedConfigFormat("Unsupported configuration format. Use .json")
    }

    private func applyCommandLineOptions(to config: inout FilterConfiguration) {
        if !languages.isEmpty {
            config.languages = Set(languages.compactMap { DetectedLanguage(rawValue: $0) })
        }
        config.minLength = minLength
        config.excludeDuplicates = excludeDuplicates
        config.excludeEmpty = excludeEmpty
        config.excludeNumeric = excludeNumeric
    }

    private func configureFilters(filterManager: FilterManager, config: FilterConfiguration) {
        filterManager.clearFilters()

        // Add language filter
        if !config.languages.isEmpty {
            let languageFilter = LanguageFilter(targetLanguages: config.languages)
            filterManager.addFilter(languageFilter)
        }

        // Add content filter
        let contentFilter = ContentFilter(
            minLength: config.minLength,
            excludeEmpty: config.excludeEmpty,
            excludeNumericOnly: config.excludeNumeric
        )
        filterManager.addFilter(contentFilter)

        // Add duplicate filter
        if config.excludeDuplicates {
            let duplicateFilter = DuplicateFilter(excludeDuplicates: true)
            filterManager.addFilter(duplicateFilter)
        }
    }

    private func printStatistics(filterResult: FilterResult) {
        print("\n📊 Filter Statistics:")
        print("Original count: \(filterResult.originalCount)")
        print("Filtered count: \(filterResult.filteredCount)")
        print("Filter ratio: \(String(format: "%.1f", filterResult.filterRatio * 100))%")
        print("Processing time: \(String(format: "%.2f", filterResult.totalDuration))s")

        if !filterResult.filterSteps.isEmpty {
            print("\nFilter steps:")
            for step in filterResult.filterSteps {
                print("  \(step.filterName): \(step.beforeCount) → \(step.afterCount) (\(String(format: "%.2f", step.duration))s)")
            }
        }
    }

    private func generateOutput(
        results: [StringLocation],
        format: OutputFormat,
        includeStats: Bool,
        filterResult: FilterResult?
    ) throws -> String {
        switch format {
        case .json:
            return try generateJSONOutput(results: results, includeStats: includeStats, filterResult: filterResult)
        case .csv:
            return generateCSVOutput(results: results)
        case .text:
            return generateTextOutput(results: results)
        }
    }

    private func generateJSONOutput(
        results: [StringLocation],
        includeStats: Bool,
        filterResult: FilterResult?
    ) throws -> String {
        var output: [String: Any] = [
            "results": results.map { location in
                [
                    "file": location.file,
                    "line": location.line,
                    "column": location.column,
                    "content": location.content,
                    "isLocalized": location.isLocalized
                ]
            }
        ]

        if includeStats, let filterResult = filterResult {
            output["statistics"] = [
                "originalCount": filterResult.originalCount,
                "filteredCount": filterResult.filteredCount,
                "filterRatio": filterResult.filterRatio,
                "processingTime": filterResult.totalDuration,
                "filterSteps": filterResult.filterSteps.map { step in
                    [
                        "filterName": step.filterName,
                        "beforeCount": step.beforeCount,
                        "afterCount": step.afterCount,
                        "processingTime": step.duration
                    ]
                }
            ]
        }

        let jsonData = try JSONSerialization.data(withJSONObject: output, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    private func generateCSVOutput(results: [StringLocation]) -> String {
        var csv = "File,Line,Column,Content,IsLocalized\n"
        for result in results {
            let escapedContent = result.content.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(result.file)\",\(result.line),\(result.column),\"\(escapedContent)\",\(result.isLocalized)\n"
        }
        return csv
    }

    private func generateTextOutput(results: [StringLocation]) -> String {
        var text = ""
        for result in results {
            text += "\(result.file):\(result.line):\(result.column): \(result.content)\n"
        }
        return text
    }
}

enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
    case json
    case csv
    case text
}

struct FilterConfiguration: Codable {
    var languages: Set<DetectedLanguage> = Set(DetectedLanguage.allCases)
    var minLength: Int = 1
    var excludeDuplicates: Bool = false
    var excludeEmpty: Bool = true
    var excludeNumeric: Bool = false
}

enum CLIError: Error, LocalizedError {
    case unsupportedConfigFormat(String)
    case invalidProjectPath(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedConfigFormat(let message):
            return "Unsupported configuration format: \(message)"
        case .invalidProjectPath(let path):
            return "Invalid project path: \(path)"
        }
    }
}