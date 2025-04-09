import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("settings.appearance", comment: ""))) {
                    Picker(NSLocalizedString("settings.appearance", comment: ""), selection: $settingsManager.appearanceMode) {
                        Text(NSLocalizedString("settings.appearance.light", comment: "")).tag(AppearanceMode.light)
                        Text(NSLocalizedString("settings.appearance.dark", comment: "")).tag(AppearanceMode.dark)
                        Text(NSLocalizedString("settings.appearance.system", comment: "")).tag(AppearanceMode.system)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text(NSLocalizedString("settings.language", comment: ""))) {
                    Picker(NSLocalizedString("settings.language", comment: ""), selection: $settingsManager.language) {
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings.title", comment: ""))
            .frame(minWidth: 400, minHeight: 300)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 