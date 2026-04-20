import Foundation
import SwiftUI
import GymFlowCore

@Observable
final class SettingsStore {
    private let repository: UserSettingsRepository

    var units: WeightUnit {
        didSet { persist() }
    }
    var language: AppLanguage {
        didSet { persist() }
    }
    var defaultRestSeconds: Int {
        didSet { persist() }
    }
    var appearance: Appearance {
        didSet { persist() }
    }
    var healthSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(healthSyncEnabled, forKey: Self.healthSyncKey) }
    }

    private static let healthSyncKey = "app.health_sync_enabled"

    init(repository: UserSettingsRepository, initial: UserSettings) {
        self.repository = repository
        self.units = initial.units
        self.language = initial.language
        self.defaultRestSeconds = initial.defaultRestSeconds
        self.appearance = initial.appearance
        self.healthSyncEnabled = UserDefaults.standard.bool(forKey: Self.healthSyncKey)
    }

    var effectiveLocale: Locale {
        if let id = language.localeIdentifier {
            return Locale(identifier: id)
        }
        return .autoupdatingCurrent
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private func persist() {
        let snapshot = UserSettings(
            units: units,
            language: language,
            defaultRestSeconds: defaultRestSeconds,
            appearance: appearance
        )
        try? repository.save(snapshot)
    }
}
