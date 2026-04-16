import Foundation
import SwiftUI
import GymFlowCore

@Observable
final class LanguageManager {
    private let defaults: UserDefaults
    private let storageKey = "app.language"

    var selected: AppLanguage {
        didSet { defaults.set(selected.rawValue, forKey: storageKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: raw) {
            self.selected = lang
        } else {
            self.selected = .system
        }
    }

    var effectiveLocale: Locale {
        if let id = selected.localeIdentifier {
            return Locale(identifier: id)
        }
        return .autoupdatingCurrent
    }
}
