import XCTest
import GRDB
@testable import GymFlowCore

final class PRCalculatorTests: XCTestCase {
    private func makeFixture() throws -> (AppDatabase, ExerciseRepository, WorkoutRepository, PRCalculator, Exercise) {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let exercises = ExerciseRepository(database: db)
        let workouts = WorkoutRepository(database: db)
        let calc = PRCalculator(database: db)
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        return (db, exercises, workouts, calc, bench)
    }

    func test_firstSessionCreatesWeightAndE1RMPRs() throws {
        let (_, _, workouts, calc, bench) = try makeFixture()
        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 5)

        let detected = try calc.detectAndSave(workoutId: workout.id)
        XCTAssertEqual(detected.count, 2)
        XCTAssertTrue(detected.allSatisfy(\.isFirst))
        let types = Set(detected.map(\.record.type))
        XCTAssertEqual(types, [.weight, .e1rm])
    }

    func test_secondSessionBeatingWeightEmitsNewWeightPR() throws {
        let (_, _, workouts, calc, bench) = try makeFixture()
        let w1 = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let we1 = try workouts.addExercise(workoutId: w1.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        _ = try calc.detectAndSave(workoutId: w1.id)

        let w2 = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let we2 = try workouts.addExercise(workoutId: w2.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 62.5, reps: 5)

        let detected = try calc.detectAndSave(workoutId: w2.id)
        XCTAssertEqual(detected.count, 2)
        XCTAssertEqual(detected.first(where: { $0.record.type == .weight })?.record.weightKg, 62.5)
        XCTAssertFalse(detected.contains(where: \.isFirst))
    }

    func test_equalWeightIsNotAPR() throws {
        let (_, _, workouts, calc, bench) = try makeFixture()
        let w1 = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let we1 = try workouts.addExercise(workoutId: w1.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        _ = try calc.detectAndSave(workoutId: w1.id)

        let w2 = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let we2 = try workouts.addExercise(workoutId: w2.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 60, reps: 5)

        let detected = try calc.detectAndSave(workoutId: w2.id)
        XCTAssertTrue(detected.isEmpty, "tied performance shouldn't create a new PR")
    }

    func test_higherRepsAtSameWeightIsE1RMPROnly() throws {
        let (_, _, workouts, calc, bench) = try makeFixture()
        let w1 = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let we1 = try workouts.addExercise(workoutId: w1.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        _ = try calc.detectAndSave(workoutId: w1.id)

        let w2 = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let we2 = try workouts.addExercise(workoutId: w2.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 60, reps: 8)

        let detected = try calc.detectAndSave(workoutId: w2.id)
        XCTAssertEqual(detected.count, 1)
        XCTAssertEqual(detected.first?.record.type, .e1rm)
    }

    func test_warmupSetsDoNotQualifyForPR() throws {
        let (_, _, workouts, calc, bench) = try makeFixture()
        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 100, reps: 3, isWarmup: true)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 5, isWarmup: false)

        let detected = try calc.detectAndSave(workoutId: workout.id)
        XCTAssertEqual(detected.count, 2)
        let weightPR = try XCTUnwrap(detected.first(where: { $0.record.type == .weight }))
        XCTAssertEqual(weightPR.record.weightKg, 60, "warmup @100 should be ignored")
    }

    func test_sessionWithNoValidSetsProducesNoPRs() throws {
        let (_, _, workouts, calc, bench) = try makeFixture()
        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 5, isWarmup: true)

        let detected = try calc.detectAndSave(workoutId: workout.id)
        XCTAssertTrue(detected.isEmpty)
    }

    func test_detectedPRsPersistToDatabase() throws {
        let (db, _, workouts, calc, bench) = try makeFixture()
        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 70, reps: 4)

        _ = try calc.detectAndSave(workoutId: workout.id)

        let stored = try db.reader.read { db in
            try PRRecord
                .filter(Column("exercise_id") == bench.id.uuidString)
                .fetchAll(db)
        }
        XCTAssertEqual(stored.count, 2)
    }
}
