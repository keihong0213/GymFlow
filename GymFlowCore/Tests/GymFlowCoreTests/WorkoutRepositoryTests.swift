import XCTest
@testable import GymFlowCore

final class WorkoutRepositoryTests: XCTestCase {
    func test_startAddSetEnd_flow() throws {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let exercises = ExerciseRepository(database: db)
        let workouts = WorkoutRepository(database: db)

        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))

        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)

        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 10)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 9)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 8)

        try workouts.end(workoutId: workout.id)

        let sets = try workouts.sets(for: we.id)
        XCTAssertEqual(sets.count, 3)
        XCTAssertEqual(sets.map(\.setNumber), [1, 2, 3])
        XCTAssertEqual(sets.map(\.reps), [10, 9, 8])
    }

    func test_lastSets_returnsPreviousWorkoutSets() throws {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let exercises = ExerciseRepository(database: db)
        let workouts = WorkoutRepository(database: db)

        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))

        let w1 = try workouts.start(at: Date(timeIntervalSince1970: 1_000))
        let we1 = try workouts.addExercise(workoutId: w1.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 10)
        _ = try workouts.addSet(workoutExerciseId: we1.id, weightKg: 60, reps: 8)

        let w2 = try workouts.start(at: Date(timeIntervalSince1970: 2_000))
        let we2 = try workouts.addExercise(workoutId: w2.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 62.5, reps: 10)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 62.5, reps: 9)
        _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 62.5, reps: 8)

        let last = try workouts.lastSets(for: bench.id)
        XCTAssertEqual(last.count, 3)
        XCTAssertEqual(last.first?.weightKg, 62.5)
    }

    func test_cascadingDelete_workoutRemovesChildren() throws {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let exercises = ExerciseRepository(database: db)
        let workouts = WorkoutRepository(database: db)

        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 50, reps: 5)

        _ = try db.dbWriter.write { db in
            try Workout.deleteOne(db, key: workout.id.uuidString)
        }

        let remainingSets = try workouts.sets(for: we.id)
        XCTAssertTrue(remainingSets.isEmpty)
    }
}
