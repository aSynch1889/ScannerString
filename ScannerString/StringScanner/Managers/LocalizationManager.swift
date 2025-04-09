import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()
    
    private var bundle: Bundle?
    
    init() {
        // 初始化时加载当前语言的 Bundle
        bundle = Bundle.main
    }
    
    func localizedString(for key: String) -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
    
    func setLanguage(_ language: String) {
        // 更新语言设置
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // 重新加载 Bundle
        if let languagePath = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: languagePath) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }
} 
