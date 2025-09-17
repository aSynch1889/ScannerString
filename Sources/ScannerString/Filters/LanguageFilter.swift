import Foundation

// 语言过滤器
public struct LanguageFilter: StringFilter {
    public let name = "LanguageFilter"
    public let description = "过滤特定语言的字符串"

    public let targetLanguages: Set<DetectedLanguage>

    public init(targetLanguages: Set<DetectedLanguage>) {
        self.targetLanguages = targetLanguages
    }

    public init(targetLanguage: DetectedLanguage) {
        self.targetLanguages = Set([targetLanguage])
    }

    public func shouldInclude(_ location: StringLocation) -> Bool {
        let detectedLanguage = location.detectedLanguage
        return targetLanguages.contains(detectedLanguage)
    }

    // 便利构造器
    public static func chinese() -> LanguageFilter {
        return LanguageFilter(targetLanguage: .chinese)
    }

    public static func english() -> LanguageFilter {
        return LanguageFilter(targetLanguage: .english)
    }

    public static func mixed() -> LanguageFilter {
        return LanguageFilter(targetLanguage: .mixed)
    }

    public static func chineseAndMixed() -> LanguageFilter {
        return LanguageFilter(targetLanguages: [.chinese, .mixed])
    }

    public static func englishAndMixed() -> LanguageFilter {
        return LanguageFilter(targetLanguages: [.english, .mixed])
    }

    public static func excludeNumericAndSymbolic() -> LanguageFilter {
        return LanguageFilter(targetLanguages: [.chinese, .english, .mixed, .unknown])
    }
}