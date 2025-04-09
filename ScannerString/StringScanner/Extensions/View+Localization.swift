extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
} 