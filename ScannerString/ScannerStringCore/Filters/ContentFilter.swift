import Foundation

// 内容过滤器
public struct ContentFilter: StringFilter {
    public let name = "ContentFilter"
    public let description = "过滤字符串内容（长度、类型等）"

    public let minLength: Int
    public let maxLength: Int?
    public let excludeEmpty: Bool
    public let excludeWhitespaceOnly: Bool
    public let excludeNumericOnly: Bool
    public let excludeSymbolicOnly: Bool
    public let excludeSingleCharacter: Bool
    public let allowedContentTypes: Set<StringContentType>?
    public let excludedContentTypes: Set<StringContentType>

    public init(
        minLength: Int = 1,
        maxLength: Int? = nil,
        excludeEmpty: Bool = true,
        excludeWhitespaceOnly: Bool = true,
        excludeNumericOnly: Bool = false,
        excludeSymbolicOnly: Bool = false,
        excludeSingleCharacter: Bool = false,
        allowedContentTypes: Set<StringContentType>? = nil,
        excludedContentTypes: Set<StringContentType> = []
    ) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.excludeEmpty = excludeEmpty
        self.excludeWhitespaceOnly = excludeWhitespaceOnly
        self.excludeNumericOnly = excludeNumericOnly
        self.excludeSymbolicOnly = excludeSymbolicOnly
        self.excludeSingleCharacter = excludeSingleCharacter
        self.allowedContentTypes = allowedContentTypes
        self.excludedContentTypes = excludedContentTypes
    }

    public func shouldInclude(_ location: StringLocation) -> Bool {
        let content = location.content

        // 空字符串检查
        if excludeEmpty && content.isEmpty {
            return false
        }

        // 纯空白字符检查
        if excludeWhitespaceOnly && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }

        // 长度检查
        if content.count < minLength {
            return false
        }

        if let maxLen = maxLength, content.count > maxLen {
            return false
        }

        // 单字符检查
        if excludeSingleCharacter && content.count == 1 {
            return false
        }

        // 纯数字检查
        if excludeNumericOnly && content.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" || $0 == "+" }) {
            return false
        }

        // 纯符号检查
        if excludeSymbolicOnly {
            let nonSymbolicCharacters = content.filter { char in
                !char.isPunctuation && !char.isSymbol && !char.isWhitespace
            }
            if nonSymbolicCharacters.isEmpty && !content.isEmpty {
                return false
            }
        }

        // 内容类型检查
        let contentType = location.contentType

        // 如果指定了允许的内容类型，只保留这些类型
        if let allowedTypes = allowedContentTypes {
            if !allowedTypes.contains(contentType) {
                return false
            }
        }

        // 排除指定的内容类型
        if excludedContentTypes.contains(contentType) {
            return false
        }

        return true
    }

    // 便利构造器
    public static func basicFilter() -> ContentFilter {
        return ContentFilter(
            minLength: 2,
            excludeEmpty: true,
            excludeWhitespaceOnly: true,
            excludeSingleCharacter: true
        )
    }

    public static func strictFilter() -> ContentFilter {
        return ContentFilter(
            minLength: 3,
            excludeEmpty: true,
            excludeWhitespaceOnly: true,
            excludeNumericOnly: true,
            excludeSymbolicOnly: true,
            excludeSingleCharacter: true,
            excludedContentTypes: [.sensitive]
        )
    }

    public static func localizationFilter() -> ContentFilter {
        return ContentFilter(
            minLength: 1,
            excludeEmpty: true,
            excludeWhitespaceOnly: true,
            allowedContentTypes: [.normal]
        )
    }

    public static func noSystemStrings() -> ContentFilter {
        return ContentFilter(
            minLength: 2,
            excludeEmpty: true,
            excludeWhitespaceOnly: true,
            excludedContentTypes: [.filePath, .url, .apiEndpoint]
        )
    }
}

// 字符串长度统计分析
public struct StringLengthAnalysis {
    public let totalCount: Int
    public let averageLength: Double
    public let minLength: Int
    public let maxLength: Int
    public let lengthDistribution: [Int: Int] // 长度 -> 数量

    public init(from results: [StringLocation]) {
        self.totalCount = results.count

        if results.isEmpty {
            self.averageLength = 0
            self.minLength = 0
            self.maxLength = 0
            self.lengthDistribution = [:]
            return
        }

        let lengths = results.map { $0.content.count }
        self.minLength = lengths.min() ?? 0
        self.maxLength = lengths.max() ?? 0
        self.averageLength = Double(lengths.reduce(0, +)) / Double(lengths.count)

        var distribution: [Int: Int] = [:]
        for length in lengths {
            distribution[length, default: 0] += 1
        }
        self.lengthDistribution = distribution
    }

    public func formattedReport() -> String {
        var report = """
        字符串长度分析报告
        ==================
        总数量: \(totalCount)
        最短长度: \(minLength)
        最长长度: \(maxLength)
        平均长度: \(String(format: "%.2f", averageLength))

        长度分布（前10个）:
        """

        let sortedDistribution = lengthDistribution.sorted { $0.value > $1.value }.prefix(10)
        for (length, count) in sortedDistribution {
            let percentage = Double(count) / Double(totalCount) * 100
            report += "\n长度 \(length): \(count) 个 (\(String(format: "%.1f", percentage))%)"
        }

        return report
    }
}

// 内容类型统计分析
public struct ContentTypeAnalysis {
    public let totalCount: Int
    public let typeDistribution: [StringContentType: Int]

    public init(from results: [StringLocation]) {
        self.totalCount = results.count

        var distribution: [StringContentType: Int] = [:]
        for result in results {
            let contentType = result.contentType
            distribution[contentType, default: 0] += 1
        }
        self.typeDistribution = distribution
    }

    public func formattedReport() -> String {
        var report = """
        内容类型分析报告
        ================
        总数量: \(totalCount)

        类型分布:
        """

        let sortedDistribution = typeDistribution.sorted { $0.value > $1.value }
        for (type, count) in sortedDistribution {
            let percentage = Double(count) / Double(totalCount) * 100
            report += "\n\(type.displayName): \(count) 个 (\(String(format: "%.1f", percentage))%)"
        }

        return report
    }
}