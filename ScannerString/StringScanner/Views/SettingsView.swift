import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    private let supportedLanguages = [
        ("en", "English"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("ja", "日本語")
    ]
    
    @State private var languageChanged = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("settings.language", comment: ""))) {
                Picker(NSLocalizedString("settings.language", comment: ""), selection: $appLanguage) {
                    ForEach(supportedLanguages, id: \.0) { code, nativeName in
                        Text(nativeName).tag(code)
                    }
                }
                .onChange(of: appLanguage) { oldValue, newValue in
                    UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: .languageChanged, object: nil)
                    languageChanged.toggle()
                }
            }
            
            Section(header: Text(NSLocalizedString("settings.appearance", comment: ""))) {
                Toggle(NSLocalizedString("settings.appearance.dark", comment: ""), isOn: $isDarkMode)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 20)
        .frame(width: 400)
        .frame(minHeight: 200)
        .id(languageChanged)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("com.scannerstring.languageChanged")
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 