import SwiftUI
import GymFlowCore

struct SettingsView: View {
    @Environment(SettingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var binding = store
        return NavigationStack {
            Form {
                Section("settings.units") {
                    Picker("settings.units", selection: $binding.units) {
                        Text(verbatim: "kg").tag(WeightUnit.kg)
                        Text(verbatim: "lb").tag(WeightUnit.lb)
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings.language") {
                    Picker("settings.language", selection: $binding.language) {
                        Text("language.system").tag(AppLanguage.system)
                        Text("language.zh-Hant").tag(AppLanguage.zhHant)
                        Text("language.zh-Hans").tag(AppLanguage.zhHans)
                        Text("language.en").tag(AppLanguage.en)
                        Text("language.ja").tag(AppLanguage.ja)
                        Text("language.ko").tag(AppLanguage.ko)
                    }
                }

                Section("settings.rest_default") {
                    Stepper(value: $binding.defaultRestSeconds, in: 30...300, step: 15) {
                        Text("settings.rest_seconds \(store.defaultRestSeconds)")
                            .monospacedDigit()
                    }
                }

                Section("settings.appearance") {
                    Picker("settings.appearance", selection: $binding.appearance) {
                        Text("settings.appearance.system").tag(Appearance.system)
                        Text("settings.appearance.light").tag(Appearance.light)
                        Text("settings.appearance.dark").tag(Appearance.dark)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }
}
