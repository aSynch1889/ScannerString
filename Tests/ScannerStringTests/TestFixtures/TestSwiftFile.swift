import Foundation

class TestViewController: NSObject {

    func viewDidLoad() {

        // 英文字符串
        let englishString = "Hello World"
        let longEnglishText = "This is a longer English text for testing purposes"

        // 中文字符串
        let chineseString = "你好世界"
        let traditionalChineseString = "繁體中文測試"

        // 混合语言字符串
        let mixedString = "Hello 世界 Testing 测试"

        // 本地化字符串
        let localizedString = NSLocalizedString("app.title", comment: "Application title")
        let anotherLocalizedString = NSLocalizedString("welcome.message", comment: "Welcome message")

        // 空字符串和短字符串
        let emptyString = ""
        let singleChar = "A"
        let twoChars = "AB"

        // 纯数字和符号
        let numericString = "12345"
        let symbolString = "!@#$%"

        // URL和文件路径
        let urlString = "https://www.example.com/api/v1/users"
        let filePathString = "/Users/username/Documents/file.txt"

        // 重复字符串（用于测试重复检测）
        let duplicateString1 = "Duplicate Test String"
        let duplicateString2 = "Duplicate Test String"

        // 正则表达式字符串
        let emailRegexString = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let phoneRegexString = "^\\d{3}-\\d{3}-\\d{4}$"
    }

    func testFunction() {
        print("Test function called")
        let functionString = "Function String"
    }
}