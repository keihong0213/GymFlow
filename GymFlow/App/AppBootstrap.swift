import Foundation
import GymFlowCore

@Observable
final class AppBootstrap {
    let database: AppDatabase
    let exerciseRepo: ExerciseRepository
    let workoutRepo: WorkoutRepository
    let routineRepo: RoutineRepository
    let prRepo: PRRepository
    let settingsRepo: UserSettingsRepository
    let analyticsRepo: AnalyticsRepository
    let prCalculator: PRCalculator
    let localizer: ExerciseLocalizer
    let settingsStore: SettingsStore
    let analytics: Analytics

    init() throws {
        let fm = FileManager.default
        let supportDir = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbPath = supportDir.appendingPathComponent("gymflow.sqlite")
        self.database = try AppDatabase.onDisk(path: dbPath)
        _ = try ExerciseSeedLoader.seed(into: database)
        _ = try RoutineSeedLoader.seed(into: database)
        self.exerciseRepo = ExerciseRepository(database: database)
        self.workoutRepo = WorkoutRepository(database: database)
        self.routineRepo = RoutineRepository(database: database)
        self.prRepo = PRRepository(database: database)
        self.settingsRepo = UserSettingsRepository(database: database)
        self.analyticsRepo = AnalyticsRepository(database: database)
        self.prCalculator = PRCalculator(database: database)
        self.localizer = try ExerciseLocalizer()
        let loaded = try settingsRepo.load()
        let migrated = AppBootstrap.migratingLegacyLanguage(loaded, repository: settingsRepo)
        self.settingsStore = SettingsStore(repository: settingsRepo, initial: migrated)
        self.analytics = Analytics(repository: analyticsRepo)
    }

    private static let legacyLanguageKey = "app.language"

    private static func migratingLegacyLanguage(
        _ loaded: UserSettings,
        repository: UserSettingsRepository
    ) -> UserSettings {
        let defaults = UserDefaults.standard
        guard let raw = defaults.string(forKey: legacyLanguageKey) else { return loaded }
        defaults.removeObject(forKey: legacyLanguageKey)
        guard loaded.language == .system,
              let legacy = AppLanguage(rawValue: raw),
              legacy != .system else {
            return loaded
        }
        var updated = loaded
        updated.language = legacy
        try? repository.save(updated)
        return updated
    }
}
