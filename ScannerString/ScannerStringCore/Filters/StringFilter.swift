import Foundation

// 过滤器协议
public protocol StringFilter {
    func shouldInclude(_ location: StringLocation) -> Bool
    var name: String { get }
    var description: String { get }
}

// 扩展StringLocation以支持更多信息
extension StringLocation {
    // 检测语言类型
    public var detectedLanguage: DetectedLanguage {
        return detectLanguage(content)
    }

    // 检测内容类型
    public var contentType: StringContentType {
        return detectContentType(content)
    }
}

// 检测到的语言类型
public enum DetectedLanguage: String, CaseIterable, Codable {
    case chinese = "chinese"
    case english = "english"
    case mixed = "mixed"
    case numeric = "numeric"
    case symbolic = "symbolic"
    case unknown = "unknown"

    public var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .mixed: return "mixed_language".localized
        case .numeric: return "numbers".localized
        case .symbolic: return "symbols".localized
        case .unknown: return "unknown".localized
        }
    }
}

// 字符串内容类型
public enum StringContentType: String, CaseIterable, Codable {
    case normal = "normal"
    case url = "url"
    case filePath = "filePath"
    case apiEndpoint = "apiEndpoint"
    case colorValue = "colorValue"
    case sensitive = "sensitive"

    public var displayName: String {
        switch self {
        case .normal: return "plain_text".localized
        case .url: return "url_address".localized
        case .filePath: return "file_path".localized
        case .apiEndpoint: return "api_endpoint".localized
        case .colorValue: return "color_value".localized
        case .sensitive: return "sensitive_info".localized
        }
    }
}

// 语言检测函数
public func detectLanguage(_ text: String) -> DetectedLanguage {
    guard !text.isEmpty else { return .unknown }

    // 中文字符集（包括中日韩统一汉字）
    let chineseCharacterSet = CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}")
    // 日文平假名和片假名
    let japaneseCharacterSet = CharacterSet(charactersIn: "\u{3040}"..."\u{309f}").union(CharacterSet(charactersIn: "\u{30a0}"..."\u{30ff}"))
    // 韩文字符集
    let koreanCharacterSet = CharacterSet(charactersIn: "\u{ac00}"..."\u{d7af}")

    // 合并CJK字符集
    let cjkCharacterSet = chineseCharacterSet.union(japaneseCharacterSet).union(koreanCharacterSet)

    // ASCII字母数字字符集
    let asciiCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

    // 数字字符集
    let numberCharacterSet = CharacterSet.decimalDigits

    // 符号字符集
    let symbolCharacterSet = CharacterSet.punctuationCharacters.union(CharacterSet.symbols)

    // 统计各种字符的数量
    let totalCount = text.count
    var cjkCount = 0
    var asciiCount = 0
    var numberCount = 0
    var symbolCount = 0

    for scalar in text.unicodeScalars {
        if cjkCharacterSet.contains(scalar) {
            cjkCount += 1
        } else if asciiCharacterSet.contains(scalar) {
            asciiCount += 1
        } else if numberCharacterSet.contains(scalar) {
            numberCount += 1
        } else if symbolCharacterSet.contains(scalar) {
            symbolCount += 1
        }
    }

    let cjkRatio = Double(cjkCount) / Double(totalCount)
    let asciiRatio = Double(asciiCount) / Double(totalCount)
    let numberRatio = Double(numberCount) / Double(totalCount)
    let symbolRatio = Double(symbolCount) / Double(totalCount)

    // 判断语言类型
    if numberRatio > 0.8 {
        return .numeric
    }

    if symbolRatio > 0.5 {
        return .symbolic
    }

    if cjkRatio > 0.3 && asciiRatio > 0.3 {
        return .mixed
    }

    if cjkRatio > 0.3 {
        return .chinese
    }

    if asciiRatio > 0.5 {
        return .english
    }

    return .unknown
}

// 内容类型检测函数
public func detectContentType(_ text: String) -> StringContentType {
    let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    // URL检测
    if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") || lowercased.hasPrefix("ftp://") {
        return .url
    }

    // API端点检测
    if lowercased.contains("/api/") || lowercased.contains("/v1/") || lowercased.contains("/v2/") {
        return .apiEndpoint
    }

    // 文件路径检测
    if lowercased.hasPrefix("/") || lowercased.contains(":/") || lowercased.contains("\\") {
        return .filePath
    }

    // 颜色值检测（十六进制颜色）
    if lowercased.hasPrefix("#") && lowercased.count == 7 {
        let hexPart = String(lowercased.dropFirst())
        if hexPart.allSatisfy({ $0.isHexDigit }) {
            return .colorValue
        }
    }

    // 敏感信息检测（简单的关键词检测）
    let sensitiveKeywords = ["password", "secret", "key", "token", "auth", "密码", "秘钥", "令牌"]
    for keyword in sensitiveKeywords {
        if lowercased.contains(keyword) {
            return .sensitive
        }
    }

    return .normal
}

extension Character {
    var isHexDigit: Bool {
        return self.isNumber || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}
