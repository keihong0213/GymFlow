import Foundation
import GymFlowCore

@Observable
final class AppBootstrap {
    let database: AppDatabase
    let exerciseRepo: ExerciseRepository
    let workoutRepo: WorkoutRepository
    let localizer: ExerciseLocalizer

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
        self.exerciseRepo = ExerciseRepository(database: database)
        self.workoutRepo = WorkoutRepository(database: database)
        self.localizer = try ExerciseLocalizer()
    }
}
