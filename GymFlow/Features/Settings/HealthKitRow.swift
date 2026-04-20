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
