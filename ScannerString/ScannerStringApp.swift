//
//  ScannerStringApp.swift
//  ScannerString
//
//  Created by 华子 on 2025/4/10.
//

import SwiftUI

@main
struct ScannerStringApp: App {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingSettings = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settingsManager.colorScheme)
                .environment(\.locale, Locale(identifier: settingsManager.language.rawValue))
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("settings.title", comment: "")) {
                    showingSettings.toggle()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
