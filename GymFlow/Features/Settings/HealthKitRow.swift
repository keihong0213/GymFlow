//
//  HealthKitRow.swift
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

import SwiftUI
import GymFlowCore

struct HealthKitRow: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var settings

    @State private var requesting = false

    var body: some View {
        @Bindable var settings = settings
        Toggle(isOn: Binding(
            get: { settings.healthSyncEnabled && bootstrap.healthKit.status != .denied && bootstrap.healthKit.status != .unavailable },
            set: { newValue in
                if newValue {
                    settings.healthSyncEnabled = true
                    Task { await requestAuth() }
                } else {
                    settings.healthSyncEnabled = false
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("settings.health_sync")
                if requesting {
                    Text("settings.health_requesting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(bootstrap.healthKit.status == .unavailable)
    }

    private var statusText: LocalizedStringKey {
        switch bootstrap.healthKit.status {
        case .notDetermined: return "settings.health_not_determined"
        case .authorized: return "settings.health_authorized"
        case .denied: return "settings.health_denied"
        case .unavailable: return "settings.health_unavailable"
        }
    }

    private func requestAuth() async {
        requesting = true
        let result = await bootstrap.healthKit.requestAuthorization()
        requesting = false
        if result == .denied || result == .unavailable {
            settings.healthSyncEnabled = false
        }
    }
}
