import Foundation

// 过滤器管理器
public class FilterManager {
    private var filters: [StringFilter] = []

    public init() {}

    // 添加过滤器
    public func addFilter(_ filter: StringFilter) {
        filters.append(filter)
    }

    // 移除所有过滤器
    public func clearFilters() {
        filters.removeAll()
    }

    // 获取当前过滤器列表
    public func getFilters() -> [StringFilter] {
        return filters
    }

    // 应用所有过滤器
    public func applyFilters(to results: [StringLocation]) -> FilterResult {
        let startTime = Date()
        let originalCount = results.count

        var filteredResults = results
        var filterSteps: [FilterStep] = []

        for filter in filters {
            let stepStartTime = Date()
            let beforeCount = filteredResults.count

            filteredResults = filteredResults.filter { filter.shouldInclude($0) }

            let afterCount = filteredResults.count
            let stepDuration = Date().timeIntervalSince(stepStartTime)

            filterSteps.append(FilterStep(
                filterName: filter.name,
                filterDescription: filter.description,
                beforeCount: beforeCount,
                afterCount: afterCount,
                filteredCount: beforeCount - afterCount,
                duration: stepDuration
            ))
        }

        let totalDuration = Date().timeIntervalSince(startTime)

        return FilterResult(
            originalResults: results,
            filteredResults: filteredResults,
            filterSteps: filterSteps,
            totalDuration: totalDuration
        )
    }

    // 预设过滤器配置
    public static func createBasicConfiguration() -> FilterManager {
        let manager = FilterManager()
        manager.addFilter(ContentFilter.basicFilter())
        manager.addFilter(LanguageFilter.excludeNumericAndSymbolic())
        return manager
    }

    public static func createStrictConfiguration() -> FilterManager {
        let manager = FilterManager()
        manager.addFilter(ContentFilter.strictFilter())
        manager.addFilter(LanguageFilter.chineseAndMixed())
        manager.addFilter(DuplicateFilter(excludeDuplicates: true))
        return manager
    }

    public static func createLocalizationConfiguration() -> FilterManager {
        let manager = FilterManager()
        manager.addFilter(ContentFilter.localizationFilter())
        manager.addFilter(LanguageFilter.chineseAndMixed())
        return manager
    }

    public static func createEnglishOnlyConfiguration() -> FilterManager {
        let manager = FilterManager()
        manager.addFilter(ContentFilter.noSystemStrings())
        manager.addFilter(LanguageFilter.englishAndMixed())
        return manager
    }
}

// 过滤步骤信息
public struct FilterStep {
    public let filterName: String
    public let filterDescription: String
    public let beforeCount: Int
    public let afterCount: Int
    public let filteredCount: Int
    public let duration: TimeInterval

    public init(filterName: String, filterDescription: String, beforeCount: Int, afterCount: Int, filteredCount: Int, duration: TimeInterval) {
        self.filterName = filterName
        self.filterDescription = filterDescription
        self.beforeCount = beforeCount
        self.afterCount = afterCount
        self.filteredCount = filteredCount
        self.duration = duration
    }

    public var filterRatio: Double {
        return beforeCount > 0 ? Double(filteredCount) / Double(beforeCount) : 0.0
    }
}

// 过滤结果
public struct FilterResult {
    public let originalResults: [StringLocation]
    public let filteredResults: [StringLocation]
    public let filterSteps: [FilterStep]
    public let totalDuration: TimeInterval

    public init(originalResults: [StringLocation], filteredResults: [StringLocation], filterSteps: [FilterStep], totalDuration: TimeInterval) {
        self.originalResults = originalResults
        self.filteredResults = filteredResults
        self.filterSteps = filterSteps
        self.totalDuration = totalDuration
    }

    public var originalCount: Int { originalResults.count }
    public var filteredCount: Int { filteredResults.count }
    public var removedCount: Int { originalCount - filteredCount }
    public var filterRatio: Double {
        return originalCount > 0 ? Double(removedCount) / Double(originalCount) : 0.0
    }

    // 格式化过滤报告
    public func formattedReport() -> String {
        var report = """
        过滤器应用报告
        ==============
        原始字符串数量: \(originalCount)
        过滤后数量: \(filteredCount)
        移除数量: \(removedCount)
        过滤率: \(String(format: "%.2f", filterRatio * 100))%
        总耗时: \(String(format: "%.3f", totalDuration))秒

        过滤步骤详情:
        """

        for (index, step) in filterSteps.enumerated() {
            report += """

            \(index + 1). \(step.filterName)
               描述: \(step.filterDescription)
               处理前: \(step.beforeCount) 个
               处理后: \(step.afterCount) 个
               移除: \(step.filteredCount) 个 (\(String(format: "%.2f", step.filterRatio * 100))%)
               耗时: \(String(format: "%.3f", step.duration))秒
            """
        }

        return report
    }

    // 生成分析统计
    public func generateAnalysis() -> FilterAnalysis {
        return FilterAnalysis(
            originalResults: originalResults,
            filteredResults: filteredResults,
            filterSteps: filterSteps
        )
    }
}

// 过滤分析结果
public struct FilterAnalysis {
    public let lengthAnalysis: StringLengthAnalysis
    public let contentTypeAnalysis: ContentTypeAnalysis
    public let duplicateAnalysis: DuplicateAnalysisResult
    public let languageAnalysis: LanguageAnalysis

    public init(originalResults: [StringLocation], filteredResults: [StringLocation], filterSteps: [FilterStep]) {
        self.lengthAnalysis = StringLengthAnalysis(from: filteredResults)
        self.contentTypeAnalysis = ContentTypeAnalysis(from: filteredResults)
        self.duplicateAnalysis = DuplicateAnalysisResult(from: filteredResults)
        self.languageAnalysis = LanguageAnalysis(from: filteredResults)
    }

    public func fullReport() -> String {
        return """
        完整分析报告
        ============

        \(lengthAnalysis.formattedReport())

        \(contentTypeAnalysis.formattedReport())

        \(duplicateAnalysis.formattedReport())

        \(languageAnalysis.formattedReport())
        """
    }
}

// 语言分析
public struct LanguageAnalysis {
    public let totalCount: Int
    public let languageDistribution: [DetectedLanguage: Int]

    public init(from results: [StringLocation]) {
        self.totalCount = results.count

        var distribution: [DetectedLanguage: Int] = [:]
        for result in results {
            let language = result.detectedLanguage
            distribution[language, default: 0] += 1
        }
        self.languageDistribution = distribution
    }

    public func formattedReport() -> String {
        var report = """
        语言分布分析报告
        ================
        总数量: \(totalCount)

        语言分布:
        """

        let sortedDistribution = languageDistribution.sorted { $0.value > $1.value }
        for (language, count) in sortedDistribution {
            let percentage = Double(count) / Double(totalCount) * 100
            report += "\n\(language.displayName): \(count) 个 (\(String(format: "%.1f", percentage))%)"
        }

        return report
    }
}