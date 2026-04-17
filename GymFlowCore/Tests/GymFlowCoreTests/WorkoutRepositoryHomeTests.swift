import XCTest
@testable import GymFlowCore

final class WorkoutRepositoryHomeTests: XCTestCase {
    private func makeFixture() throws -> (AppDatabase, ExerciseRepository, WorkoutRepository) {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        return (db, ExerciseRepository(database: db), WorkoutRepository(database: db))
    }

    func test_lastWorkout_returnsMostRecentByStartedAt() throws {
        let (_, exercises, workouts) = try makeFixture()
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))

        let older = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        _ = try workouts.addExercise(workoutId: older.id, exerciseId: bench.id)

        let newer = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        _ = try workouts.addExercise(workoutId: newer.id, exerciseId: bench.id)

        let middle = try workouts.start(at: Date(timeIntervalSince1970: 1_500))
        _ = try workouts.addExercise(workoutId: middle.id, exerciseId: bench.id)

        let last = try XCTUnwrap(try workouts.lastWorkout())
        XCTAssertEqual(last.id, newer.id)
    }

    func test_workouts_since_returnsOnlyAfterCutoff() throws {
        let (_, _, workouts) = try makeFixture()
        _ = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        _ = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        _ = try workouts.start(at: Date(timeIntervalSince1970: 3_000))

        let result = try workouts.workouts(since: Date(timeIntervalSince1970: 1_500))
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.startedAt).sorted(), result.map(\.startedAt))
    }

    func test_summary_aggregatesExerciseAndSetCountsAndVolume() throws {
        let (_, exercises, workouts) = try makeFixture()
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        let squat = try XCTUnwrap(try exercises.find(slug: "back_squat"))

        let workout = try workouts.start()
        let we1 = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 10)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 8)

        let we2 = try workouts.addExercise(workoutId: workout.id, exerciseId: squat.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 100, reps: 5)

        let summary = try XCTUnwrap(try workouts.summary(for: workout.id))
        XCTAssertEqual(summary.exerciseCount, 2)
        XCTAssertEqual(summary.setCount, 3)
        let expected: Double = (60.0 * 10.0) + (60.0 * 8.0) + (100.0 * 5.0)
        XCTAssertEqual(summary.totalVolumeKg, expected, accuracy: 1e-9)
    }

    func test_summary_emptyWorkoutReturnsZeroes() throws {
        let (_, _, workouts) = try makeFixture()
        let workout = try workouts.start()
        let summary = try XCTUnwrap(try workouts.summary(for: workout.id))
        XCTAssertEqual(summary.exerciseCount, 0)
        XCTAssertEqual(summary.setCount, 0)
        XCTAssertEqual(summary.totalVolumeKg, 0)
    }
}
