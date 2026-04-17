import XCTest
@testable import GymFlowCore

final class ExerciseHistoryTests: XCTestCase {
    private func makeFixture() throws -> (AppDatabase, ExerciseRepository, WorkoutRepository, PRRepository, PRCalculator, Exercise) {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let exercises = ExerciseRepository(database: db)
        let workouts = WorkoutRepository(database: db)
        let prs = PRRepository(database: db)
        let calc = PRCalculator(database: db)
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        return (db, exercises, workouts, prs, calc, bench)
    }

    func test_history_returnsMostRecentFirst_withTopSetByE1RM() throws {
        let (_, _, workouts, _, _, bench) = try makeFixture()

        let w1 = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let we1 = try workouts.addExercise(workoutId: w1.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 8)

        let w2 = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let we2 = try workouts.addExercise(workoutId: w2.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 65, reps: 5)

        let history = try workouts.history(for: bench.id)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].workoutId, w2.id)
        XCTAssertEqual(history[0].topSet?.weightKg, 65)
        XCTAssertEqual(history[1].workoutId, w1.id)
        XCTAssertEqual(history[1].topSet?.reps, 8, "60x8 has higher e1rm than 60x5")
    }

    func test_history_respectsLimit() throws {
        let (_, _, workouts, _, _, bench) = try makeFixture()
        for i in 0..<12 {
            let w = try workouts.start(at: Date(timeIntervalSince1970: TimeInterval(1_000 + i * 100)))
            let we = try workouts.addExercise(workoutId: w.id, exerciseId: bench.id)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 5)
        }
        let history = try workouts.history(for: bench.id, limit: 5)
        XCTAssertEqual(history.count, 5)
    }

    func test_history_ignoresWarmupsInTopSetAndVolume() throws {
        let (_, _, workouts, _, _, bench) = try makeFixture()
        let w = try workouts.start()
        let we = try workouts.addExercise(workoutId: w.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 100, reps: 3, isWarmup: true)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 10)

        let history = try workouts.history(for: bench.id)
        XCTAssertEqual(history.first?.topSet?.weightKg, 60)
        XCTAssertEqual(history.first?.setCount, 1)
        XCTAssertEqual(history.first?.totalVolumeKg, 600)
    }

    func test_history_emptyWhenExerciseNeverUsed() throws {
        let (_, exercises, workouts, _, _, _) = try makeFixture()
        let row = try XCTUnwrap(try exercises.find(slug: "barbell_row"))
        XCTAssertTrue(try workouts.history(for: row.id).isEmpty)
    }

    func test_history_collapsesDuplicateExercisePerWorkout() throws {
        let (_, _, workouts, _, _, bench) = try makeFixture()
        let w = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        // Same exercise added twice in the same workout.
        let we1 = try workouts.addExercise(workoutId: w.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        let we2 = try workouts.addExercise(workoutId: w.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 70, reps: 3)

        let history = try workouts.history(for: bench.id)
        XCTAssertEqual(history.count, 1, "one workout → one history row even if the exercise is added twice")
        XCTAssertEqual(history.first?.setCount, 3, "sets across both workout_exercise rows are combined")
        XCTAssertEqual(history.first?.totalVolumeKg, 810.0)
        XCTAssertEqual(history.first?.topSet?.weightKg, 70, "top set picks the heavier working set across duplicates")
    }

    func test_history_duplicateExerciseDoesNotConsumeLimit() throws {
        let (_, _, workouts, _, _, bench) = try makeFixture()

        // Newer workout: exercise added twice, one proper set each.
        let wNew = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let weN1 = try workouts.addExercise(workoutId: wNew.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: weN1.id, weightKg: 60, reps: 5)
        let weN2 = try workouts.addExercise(workoutId: wNew.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: weN2.id, weightKg: 70, reps: 3)

        // Older workout — must still appear under limit=2.
        let wOld = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let weO = try workouts.addExercise(workoutId: wOld.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: weO.id, weightKg: 55, reps: 5)

        let history = try workouts.history(for: bench.id, limit: 2)
        XCTAssertEqual(history.map(\.workoutId), [wNew.id, wOld.id])
    }

    func test_history_skipsWorkoutsWithNoWorkingSets_andDoesNotConsumeLimit() throws {
        let (_, _, workouts, _, _, bench) = try makeFixture()

        // Workout A: only a warmup, no working set — should be excluded.
        let wA = try workouts.start(at: Date(timeIntervalSince1970: 3_000))
        let weA = try workouts.addExercise(workoutId: wA.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: weA.id, weightKg: 40, reps: 5, isWarmup: true)

        // Workout B: exercise added but no set at all — should be excluded.
        let wB = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        _ = try workouts.addExercise(workoutId: wB.id, exerciseId: bench.id)

        // Workout C: legit working set — should appear.
        let wC = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let weC = try workouts.addExercise(workoutId: wC.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: weC.id, weightKg: 60, reps: 5)

        // With limit=1, bogus entries must not consume the slot that belongs to C.
        let history = try workouts.history(for: bench.id, limit: 1)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.workoutId, wC.id)
    }

    func test_currentPRs_returnsBestPerType() throws {
        let (_, _, workouts, prs, calc, bench) = try makeFixture()

        let w1 = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let we1 = try workouts.addExercise(workoutId: w1.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 5)
        _ = try calc.detectAndSave(workoutId: w1.id)

        let w2 = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let we2 = try workouts.addExercise(workoutId: w2.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 70, reps: 4)
        _ = try calc.detectAndSave(workoutId: w2.id)

        let current = try prs.currentPRs(for: bench.id)
        XCTAssertEqual(current.count, 2)
        let byType = Dictionary(uniqueKeysWithValues: current.map { ($0.type, $0) })
        XCTAssertEqual(byType[.weight]?.weightKg, 70)
        XCTAssertEqual(byType[.e1rm]?.weightKg, 70)
    }

    func test_allPRs_returnsChronologicalForCharting() throws {
        let (_, _, workouts, prs, calc, bench) = try makeFixture()
        for (i, weight) in [60.0, 62.5, 65.0].enumerated() {
            let w = try workouts.start(at: Date(timeIntervalSince1970: TimeInterval(1_000 + i * 100)))
            let we = try workouts.addExercise(workoutId: w.id, exerciseId: bench.id)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: weight, reps: 5)
            _ = try calc.detectAndSave(workoutId: w.id)
        }
        let chronological = try prs.allPRs(for: bench.id)
        XCTAssertEqual(chronological.count, 6, "3 sessions × 2 PR types")
        let dates = chronological.map(\.achievedAt)
        XCTAssertEqual(dates, dates.sorted())
    }
}
