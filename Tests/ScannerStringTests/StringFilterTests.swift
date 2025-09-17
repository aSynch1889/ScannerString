import XCTest
@testable import ScannerString

final class StringFilterTests: XCTestCase {

    func testLanguageDetection() {
        // 中文检测
        XCTAssertEqual(detectLanguage("你好世界"), .chinese)
        XCTAssertEqual(detectLanguage("繁體中文測試"), .chinese)

        // 英文检测
        XCTAssertEqual(detectLanguage("Hello World"), .english)
        XCTAssertEqual(detectLanguage("Test String"), .english)

        // 混合语言检测
        XCTAssertEqual(detectLanguage("Hello 世界"), .mixed)
        XCTAssertEqual(detectLanguage("测试 Test"), .mixed)

        // 数字检测
        XCTAssertEqual(detectLanguage("12345"), .numeric)
        XCTAssertEqual(detectLanguage("123.45"), .numeric)

        // 符号检测
        XCTAssertEqual(detectLanguage("!@#$%"), .symbolic)
        XCTAssertEqual(detectLanguage("***"), .symbolic)

        // 空字符串
        XCTAssertEqual(detectLanguage(""), .unknown)
    }

    func testContentTypeDetection() {
        // URL检测
        XCTAssertEqual(detectContentType("https://www.example.com"), .url)
        XCTAssertEqual(detectContentType("http://api.test.com"), .url)
        XCTAssertEqual(detectContentType("ftp://files.example.com"), .url)

        // API端点检测
        XCTAssertEqual(detectContentType("/api/v1/users"), .apiEndpoint)
        XCTAssertEqual(detectContentType("users/v2/profile"), .apiEndpoint)

        // 文件路径检测
        XCTAssertEqual(detectContentType("/Users/test/file.txt"), .filePath)
        XCTAssertEqual(detectContentType("C:\\Windows\\System32"), .filePath)

        // 颜色值检测
        XCTAssertEqual(detectContentType("#FF0000"), .colorValue)
        XCTAssertEqual(detectContentType("#123abc"), .colorValue)

        // 敏感信息检测
        XCTAssertEqual(detectContentType("my_password_123"), .sensitive)
        XCTAssertEqual(detectContentType("api_key_secret"), .sensitive)
        XCTAssertEqual(detectContentType("用户密码"), .sensitive)

        // 普通文本
        XCTAssertEqual(detectContentType("Normal text"), .normal)
        XCTAssertEqual(detectContentType("普通文本"), .normal)
    }

    func testLanguageFilter() {
        let testLocations = [
            StringLocation(file: "test.swift", line: 1, column: 1, content: "Hello World", isLocalized: false),
            StringLocation(file: "test.swift", line: 2, column: 1, content: "你好世界", isLocalized: false),
            StringLocation(file: "test.swift", line: 3, column: 1, content: "Hello 世界", isLocalized: false),
            StringLocation(file: "test.swift", line: 4, column: 1, content: "12345", isLocalized: false),
            StringLocation(file: "test.swift", line: 5, column: 1, content: "!@#$", isLocalized: false)
        ]

        // 中文过滤器
        let chineseFilter = LanguageFilter.chinese()
        let chineseResults = testLocations.filter { chineseFilter.shouldInclude($0) }
        XCTAssertEqual(chineseResults.count, 1)
        XCTAssertTrue(chineseResults.first?.content == "你好世界")

        // 英文过滤器
        let englishFilter = LanguageFilter.english()
        let englishResults = testLocations.filter { englishFilter.shouldInclude($0) }
        XCTAssertEqual(englishResults.count, 1)
        XCTAssertTrue(englishResults.first?.content == "Hello World")

        // 混合语言过滤器
        let mixedFilter = LanguageFilter.mixed()
        let mixedResults = testLocations.filter { mixedFilter.shouldInclude($0) }
        XCTAssertEqual(mixedResults.count, 1)
        XCTAssertTrue(mixedResults.first?.content == "Hello 世界")

        // 排除数字和符号过滤器
        let excludeFilter = LanguageFilter.excludeNumericAndSymbolic()
        let excludeResults = testLocations.filter { excludeFilter.shouldInclude($0) }
        XCTAssertEqual(excludeResults.count, 3) // 应该排除数字和符号
    }

    func testContentFilter() {
        let testLocations = [
            StringLocation(file: "test.swift", line: 1, column: 1, content: "", isLocalized: false),
            StringLocation(file: "test.swift", line: 2, column: 1, content: "A", isLocalized: false),
            StringLocation(file: "test.swift", line: 3, column: 1, content: "AB", isLocalized: false),
            StringLocation(file: "test.swift", line: 4, column: 1, content: "ABC", isLocalized: false),
            StringLocation(file: "test.swift", line: 5, column: 1, content: "   ", isLocalized: false),
            StringLocation(file: "test.swift", line: 6, column: 1, content: "12345", isLocalized: false),
            StringLocation(file: "test.swift", line: 7, column: 1, content: "!@#$", isLocalized: false)
        ]

        // 基础过滤器
        let basicFilter = ContentFilter.basicFilter()
        let basicResults = testLocations.filter { basicFilter.shouldInclude($0) }
        // 应该排除空字符串、单字符、纯空白
        XCTAssertTrue(basicResults.count >= 4)

        // 严格过滤器
        let strictFilter = ContentFilter.strictFilter()
        let strictResults = testLocations.filter { strictFilter.shouldInclude($0) }
        // 应该只保留长度>=3且非数字非符号的字符串
        XCTAssertTrue(strictResults.count <= basicResults.count)

        // 自定义过滤器
        let customFilter = ContentFilter(
            minLength: 2,
            maxLength: 5,
            excludeEmpty: true,
            excludeNumericOnly: true
        )
        let customResults = testLocations.filter { customFilter.shouldInclude($0) }
        XCTAssertFalse(customResults.contains { $0.content.isEmpty })
        XCTAssertFalse(customResults.contains { $0.content == "12345" })
    }

    func testDuplicateFilter() {
        let testLocations = [
            StringLocation(file: "test1.swift", line: 1, column: 1, content: "Duplicate", isLocalized: false),
            StringLocation(file: "test1.swift", line: 2, column: 1, content: "Unique1", isLocalized: false),
            StringLocation(file: "test2.swift", line: 1, column: 1, content: "Duplicate", isLocalized: false),
            StringLocation(file: "test2.swift", line: 2, column: 1, content: "Unique2", isLocalized: false),
            StringLocation(file: "test3.swift", line: 1, column: 1, content: "Duplicate", isLocalized: false)
        ]

        // 排除重复的过滤器
        let duplicateFilter = DuplicateFilter(excludeDuplicates: true)
        let filteredResults = testLocations.filter { duplicateFilter.shouldInclude($0) }

        // 应该只保留第一次出现的"Duplicate"
        XCTAssertEqual(filteredResults.count, 3) // Duplicate(第一次), Unique1, Unique2

        // 获取重复统计
        let duplicateStats = duplicateFilter.getDuplicateStatistics()
        XCTAssertEqual(duplicateStats["Duplicate"], 3)
        XCTAssertEqual(duplicateStats.count, 1) // 只有一个重复的字符串

        // 测试重复分析
        let duplicateAnalysis = DuplicateAnalysisResult(from: testLocations)
        XCTAssertEqual(duplicateAnalysis.totalStrings, 5)
        XCTAssertEqual(duplicateAnalysis.uniqueStrings, 3)
        XCTAssertEqual(duplicateAnalysis.duplicateGroups.count, 1)
        XCTAssertTrue(duplicateAnalysis.duplicateRatio > 0)
    }

    func testFilterManager() {
        let testLocations = [
            StringLocation(file: "test.swift", line: 1, column: 1, content: "Hello World", isLocalized: false),
            StringLocation(file: "test.swift", line: 2, column: 1, content: "你好世界", isLocalized: false),
            StringLocation(file: "test.swift", line: 3, column: 1, content: "A", isLocalized: false),
            StringLocation(file: "test.swift", line: 4, column: 1, content: "12345", isLocalized: false),
            StringLocation(file: "test.swift", line: 5, column: 1, content: "", isLocalized: false)
        ]

        let manager = FilterManager()
        manager.addFilter(ContentFilter.basicFilter())
        manager.addFilter(LanguageFilter.excludeNumericAndSymbolic())

        let result = manager.applyFilters(to: testLocations)

        XCTAssertTrue(result.filteredCount < result.originalCount)
        XCTAssertEqual(result.filterSteps.count, 2)
        XCTAssertTrue(result.totalDuration > 0)

        // 验证过滤步骤
        for step in result.filterSteps {
            XCTAssertTrue(step.beforeCount >= step.afterCount)
            XCTAssertTrue(step.duration >= 0)
        }
    }

    func testPresetConfigurations() {
        let testLocations = [
            StringLocation(file: "test.swift", line: 1, column: 1, content: "Hello World", isLocalized: false),
            StringLocation(file: "test.swift", line: 2, column: 1, content: "你好世界", isLocalized: false),
            StringLocation(file: "test.swift", line: 3, column: 1, content: "/path/to/file", isLocalized: false),
            StringLocation(file: "test.swift", line: 4, column: 1, content: "A", isLocalized: false)
        ]

        // 测试基础配置
        let basicManager = FilterManager.createBasicConfiguration()
        let basicResult = basicManager.applyFilters(to: testLocations)
        XCTAssertTrue(basicResult.filteredCount > 0)

        // 测试严格配置
        let strictManager = FilterManager.createStrictConfiguration()
        let strictResult = strictManager.applyFilters(to: testLocations)
        XCTAssertTrue(strictResult.filteredCount <= basicResult.filteredCount)

        // 测试本地化配置
        let localizationManager = FilterManager.createLocalizationConfiguration()
        let localizationResult = localizationManager.applyFilters(to: testLocations)
        XCTAssertTrue(localizationResult.filteredCount > 0)

        // 测试英文配置
        let englishManager = FilterManager.createEnglishOnlyConfiguration()
        let englishResult = englishManager.applyFilters(to: testLocations)
        XCTAssertTrue(englishResult.filteredCount > 0)
    }

    func testStringLocationExtensions() {
        let englishLocation = StringLocation(file: "test.swift", line: 1, column: 1, content: "Hello World", isLocalized: false)
        let chineseLocation = StringLocation(file: "test.swift", line: 2, column: 1, content: "你好世界", isLocalized: false)
        let urlLocation = StringLocation(file: "test.swift", line: 3, column: 1, content: "https://example.com", isLocalized: false)

        XCTAssertEqual(englishLocation.detectedLanguage, .english)
        XCTAssertEqual(chineseLocation.detectedLanguage, .chinese)
        XCTAssertEqual(urlLocation.contentType, .url)
    }
}