import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case light
    case dark
    case system
}

enum Language: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    
    var displayName: String {
        switch self {
        case .english:
            return NSLocalizedString("settings.language.english", comment: "")
        case .simplifiedChinese:
            return NSLocalizedString("settings.language.simplified_chinese", comment: "")
        case .traditionalChinese:
            return NSLocalizedString("settings.language.traditional_chinese", comment: "")
        case .japanese:
            return NSLocalizedString("settings.language.japanese", comment: "")
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            updateColorScheme()
        }
    }
    
    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "language")
            updateLanguage()
        }
    }
    
    @Published var colorScheme: ColorScheme?
    
    private init() {
        let savedAppearance = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: savedAppearance) ?? .system
        
        let savedLanguage = UserDefaults.standard.string(forKey: "language") ?? "en"
        self.language = Language(rawValue: savedLanguage) ?? .english
        
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        switch appearanceMode {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil
        }
    }
    
    private func updateLanguage() {
        // 这里可以添加语言切换的逻辑
        // 注意：在 iOS 中，需要重启应用才能完全应用语言更改
    }
} 