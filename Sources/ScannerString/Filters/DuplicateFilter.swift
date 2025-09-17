import Foundation

// 重复字符串过滤器
public class DuplicateFilter: StringFilter {
    public let name = "DuplicateFilter"
    public let description = "过滤重复的字符串"

    public let excludeDuplicates: Bool
    private var seenStrings: [String: Int] = [:]
    private var processedResults: [StringLocation] = []

    public init(excludeDuplicates: Bool = true) {
        self.excludeDuplicates = excludeDuplicates
    }

    public func shouldInclude(_ location: StringLocation) -> Bool {
        if excludeDuplicates {
            let currentCount = seenStrings[location.content, default: 0]
            seenStrings[location.content] = currentCount + 1
            return currentCount == 0 // 只保留第一次出现的
        }
        return true
    }

    // 获取重复字符串统计信息
    public func getDuplicateStatistics() -> [String: Int] {
        return seenStrings.filter { $0.value > 1 }
    }

    // 获取所有重复的字符串内容
    public func getDuplicateStrings() -> Set<String> {
        return Set(seenStrings.filter { $0.value > 1 }.keys)
    }

    // 重置统计
    public func reset() {
        seenStrings.removeAll()
        processedResults.removeAll()
    }

    // 获取重复字符串的详细信息
    public func getDuplicateDetails(from results: [StringLocation]) -> [DuplicateStringInfo] {
        var duplicateGroups: [String: [StringLocation]] = [:]

        // 按字符串内容分组
        for result in results {
            duplicateGroups[result.content, default: []].append(result)
        }

        // 只保留重复的字符串（出现次数 > 1）
        let duplicates = duplicateGroups.filter { $0.value.count > 1 }

        return duplicates.map { content, locations in
            DuplicateStringInfo(
                content: content,
                count: locations.count,
                locations: locations.sorted { first, second in
                    if first.file == second.file {
                        return first.line < second.line
                    }
                    return first.file < second.file
                }
            )
        }.sorted { $0.count > $1.count } // 按重复次数降序排序
    }
}

// 重复字符串信息结构
public struct DuplicateStringInfo {
    public let content: String
    public let count: Int
    public let locations: [StringLocation]

    public init(content: String, count: Int, locations: [StringLocation]) {
        self.content = content
        self.count = count
        self.locations = locations
    }
}

// 重复字符串分析结果
public struct DuplicateAnalysisResult {
    public let totalStrings: Int
    public let uniqueStrings: Int
    public let duplicateGroups: [DuplicateStringInfo]
    public let duplicateRatio: Double

    public init(from results: [StringLocation]) {
        self.totalStrings = results.count

        var contentCounts: [String: Int] = [:]
        for result in results {
            contentCounts[result.content, default: 0] += 1
        }

        self.uniqueStrings = contentCounts.count
        self.duplicateRatio = totalStrings > 0 ? Double(totalStrings - uniqueStrings) / Double(totalStrings) : 0.0

        // 创建重复组信息
        let duplicateGroups = contentCounts.filter { $0.value > 1 }
        var duplicateInfos: [DuplicateStringInfo] = []

        for (content, count) in duplicateGroups {
            let locations = results.filter { $0.content == content }
                .sorted { first, second in
                    if first.file == second.file {
                        return first.line < second.line
                    }
                    return first.file < second.file
                }
            duplicateInfos.append(DuplicateStringInfo(content: content, count: count, locations: locations))
        }

        self.duplicateGroups = duplicateInfos.sorted { $0.count > $1.count }
    }

    // 格式化输出重复分析结果
    public func formattedReport() -> String {
        var report = """
        重复字符串分析报告
        ===================
        总字符串数量: \(totalStrings)
        唯一字符串数量: \(uniqueStrings)
        重复率: \(String(format: "%.2f", duplicateRatio * 100))%

        """

        if duplicateGroups.isEmpty {
            report += "未发现重复字符串。\n"
        } else {
            report += "发现 \(duplicateGroups.count) 组重复字符串：\n\n"

            for (index, group) in duplicateGroups.enumerated() {
                report += "\(index + 1). \"\(group.content)\" (重复 \(group.count) 次)\n"
                for location in group.locations.prefix(5) { // 只显示前5个位置
                    report += "   - \(location.file):\(location.line):\(location.column)\n"
                }
                if group.locations.count > 5 {
                    report += "   - ... 还有 \(group.locations.count - 5) 个位置\n"
                }
                report += "\n"
            }
        }

        return report
    }
}