import XCTest
@testable import GymFlowCore

final class WorkoutRepositorySetMutationTests: XCTestCase {
    private func makeFixture() throws -> (AppDatabase, Exercise, WorkoutExercise, WorkoutRepository) {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let exercises = ExerciseRepository(database: db)
        let workouts = WorkoutRepository(database: db)
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        let workout = try workouts.start()
        let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
        return (db, bench, we, workouts)
    }

    func test_deleteSet_removesRowAndLeavesOthers() throws {
        let (_, _, we, workouts) = try makeFixture()
        let s1 = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 10)
        let s2 = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 9)
        let s3 = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 8)

        let deleted = try workouts.deleteSet(id: s2.id)
        XCTAssertTrue(deleted)

        let remaining = try workouts.sets(for: we.id)
        XCTAssertEqual(remaining.map(\.id), [s1.id, s3.id])
        XCTAssertEqual(remaining.map(\.setNumber), [1, 3])
    }

    func test_replaceStrengthSet_overwritesWeightAndReps() throws {
        let (_, _, we, workouts) = try makeFixture()
        let s = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 10)
        try workouts.replaceStrengthSet(id: s.id, weightKg: 62.5, reps: 8)

        let sets = try workouts.sets(for: we.id)
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets[0].weightKg, 62.5)
        XCTAssertEqual(sets[0].reps, 8)
    }
}
