//
//  ScannerStringApp.swift
//  ScannerString
//
//  Created by 华子 on 2025/4/10.
//

import SwiftUI

@main
struct ScannerStringApp: App {
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") {
            UserDefaults.standard.set([savedLanguage], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set("en", forKey: "appLanguage")
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    if let language = UserDefaults.standard.string(forKey: "appLanguage") {
                        UserDefaults.standard.set([language], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
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
