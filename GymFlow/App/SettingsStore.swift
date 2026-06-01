//
//  SettingsStore.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

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
