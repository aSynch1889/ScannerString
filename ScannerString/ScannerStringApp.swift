//
//  ScannerStringApp.swift
//  ScannerString
//
//  Created by 华子 on 2025/4/10.
//
//https://github.com/swiftlang/swift-syntax.git
import SwiftUI

@main
struct ScannerStringApp: App {
    init() {
        // 读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") {
            LocalizationManager.shared.setLanguage(savedLanguage)
        } else {
            // 默认设置为英语
            UserDefaults.standard.set("en", forKey: "appLanguage")
            LocalizationManager.shared.setLanguage("en")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // 当语言改变时，更新本地化管理器
                    if let language = UserDefaults.standard.string(forKey: "appLanguage") {
                        LocalizationManager.shared.setLanguage(language)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
        
        Settings {
            SettingsView()
        }
    }
}
