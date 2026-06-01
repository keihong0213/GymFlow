//
//  SettingsView.swift
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

struct SettingsView: View {
    @Environment(AppBootstrap.self) private var bootstrap
    @Environment(SettingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var exportJSONURL: ShareableURL?
    @State private var exportCSVURL: ShareableURL?
    @State private var exportFailed = false

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
                    .accessibilityValue(Text("a11y.seconds \(store.defaultRestSeconds)"))
                }

                Section("settings.appearance") {
                    Picker("settings.appearance", selection: $binding.appearance) {
                        Text("settings.appearance.system").tag(Appearance.system)
                        Text("settings.appearance.light").tag(Appearance.light)
                        Text("settings.appearance.dark").tag(Appearance.dark)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HealthKitRow()
                } header: {
                    Text("settings.health_section")
                }

                Section {
                    Button {
                        prepareExportJSON()
                    } label: {
                        Label("settings.export_json", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        prepareExportCSV()
                    } label: {
                        Label("settings.export_csv", systemImage: "tablecells")
                    }
                } header: {
                    Text("settings.backup_section")
                } footer: {
                    Text("settings.backup_footer")
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
            .sheet(item: $exportJSONURL) { wrapper in
                ShareSheet(url: wrapper.url)
            }
            .sheet(item: $exportCSVURL) { wrapper in
                ShareSheet(url: wrapper.url)
            }
            .alert("settings.export_failed", isPresented: $exportFailed) {
                Button("common.ok", role: .cancel) {}
            }
        }
    }

    private func prepareExportJSON() {
        do {
            exportJSONURL = ShareableURL(url: try bootstrap.backupService.writeJSONToTempFile())
        } catch {
            exportFailed = true
        }
    }

    private func prepareExportCSV() {
        do {
            exportCSVURL = ShareableURL(url: try bootstrap.backupService.writeCSVToTempFile())
        } catch {
            exportFailed = true
        }
    }
}
