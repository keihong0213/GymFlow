import XCTest
@testable import GymFlowCore

final class RoutineTests: XCTestCase {
    private func makeFixture() throws -> (AppDatabase, ExerciseRepository, RoutineRepository, WorkoutRepository) {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        return (db, ExerciseRepository(database: db), RoutineRepository(database: db), WorkoutRepository(database: db))
    }

    func test_seed_insertsBuiltInRoutines() throws {
        let (db, _, routines, _) = try makeFixture()
        let first = try RoutineSeedLoader.seed(into: db)
        XCTAssertGreaterThan(first.inserted, 0)
        XCTAssertEqual(first.skipped, 0)

        let second = try RoutineSeedLoader.seed(into: db)
        XCTAssertEqual(second.inserted, 0)
        XCTAssertEqual(second.skipped, first.inserted)

        let all = try routines.all()
        XCTAssertEqual(all.count, first.inserted)
        XCTAssertTrue(all.allSatisfy(\.isBuiltIn))
        let slugs = all.compactMap(\.slug)
        XCTAssertEqual(Set(slugs), ["push", "pull", "legs"])
    }

    func test_exercisesForBuiltIn_keepsOrderAndTargets() throws {
        let (db, _, routines, _) = try makeFixture()
        try RoutineSeedLoader.seed(into: db)
        let push = try XCTUnwrap(try routines.all().first { $0.slug == "push" })
        let links = try routines.exercises(for: push.id)
        XCTAssertEqual(links.map(\.orderIndex), Array(0..<links.count))
        XCTAssertEqual(links.first?.targetSets, 4)
        XCTAssertEqual(links.first?.targetRepsMin, 6)
        XCTAssertEqual(links.first?.targetRepsMax, 10)
    }

    func test_createCustom_insertsOrderedExercises() throws {
        let (_, exercises, routines, _) = try makeFixture()
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        let row = try XCTUnwrap(try exercises.find(slug: "barbell_row"))

        let routine = try routines.createCustom(name: "我的上肢", exerciseIds: [bench.id, row.id])
        XCTAssertFalse(routine.isBuiltIn)
        XCTAssertEqual(routine.name, "我的上肢")

        let links = try routines.exercises(for: routine.id)
        XCTAssertEqual(links.map(\.exerciseId), [bench.id, row.id])
        XCTAssertEqual(links.map(\.orderIndex), [0, 1])
    }

    func test_updateCustom_replacesExercises() throws {
        let (_, exercises, routines, _) = try makeFixture()
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        let row = try XCTUnwrap(try exercises.find(slug: "barbell_row"))
        let squat = try XCTUnwrap(try exercises.find(slug: "back_squat"))

        let routine = try routines.createCustom(name: "初版", exerciseIds: [bench.id])
        try routines.updateCustom(id: routine.id, name: "新版", exerciseIds: [squat.id, row.id])

        let updated = try XCTUnwrap(try routines.find(id: routine.id))
        XCTAssertEqual(updated.name, "新版")

        let links = try routines.exercises(for: routine.id)
        XCTAssertEqual(links.map(\.exerciseId), [squat.id, row.id])
    }

    func test_delete_removesCustomOnly() throws {
        let (db, exercises, routines, _) = try makeFixture()
        try RoutineSeedLoader.seed(into: db)
        let bench = try XCTUnwrap(try exercises.find(slug: "bench_press"))
        let custom = try routines.createCustom(name: "Temp", exerciseIds: [bench.id])

        XCTAssertTrue(try routines.delete(id: custom.id))
        XCTAssertNil(try routines.find(id: custom.id))

        let push = try XCTUnwrap(try routines.all().first { $0.slug == "push" })
        XCTAssertFalse(try routines.delete(id: push.id))
        XCTAssertNotNil(try routines.find(id: push.id))
    }

    func test_updateCustom_throwsForBuiltIn() throws {
        let (db, _, routines, _) = try makeFixture()
        try RoutineSeedLoader.seed(into: db)
        let push = try XCTUnwrap(try routines.all().first { $0.slug == "push" })

        XCTAssertThrowsError(try routines.updateCustom(id: push.id, name: "x", exerciseIds: [])) { error in
            guard case RoutineRepositoryError.builtInNotEditable = error else {
                return XCTFail("expected builtInNotEditable, got \(error)")
            }
        }
    }

    func test_updateCustom_throwsForMissing() throws {
        let (_, _, routines, _) = try makeFixture()
        XCTAssertThrowsError(try routines.updateCustom(id: UUID(), name: "x", exerciseIds: [])) { error in
            guard case RoutineRepositoryError.notFound = error else {
                return XCTFail("expected notFound, got \(error)")
            }
        }
    }

    func test_startFromRoutine_throwsWhenEmptyAndLeavesNoWorkout() throws {
        let (_, _, routines, workouts) = try makeFixture()
        let empty = try routines.createCustom(name: "Empty", exerciseIds: [])

        XCTAssertThrowsError(try workouts.startFromRoutine(routineId: empty.id)) { error in
            guard case RoutineRepositoryError.routineHasNoExercises = error else {
                return XCTFail("expected routineHasNoExercises, got \(error)")
            }
        }
        XCTAssertNil(try workouts.lastWorkout(), "no workout row should be inserted when routine is empty")
    }

    func test_startFromRoutine_createsWorkoutWithOrderedExercises() throws {
        let (db, _, routines, workouts) = try makeFixture()
        try RoutineSeedLoader.seed(into: db)
        let pull = try XCTUnwrap(try routines.all().first { $0.slug == "pull" })
        let expectedLinks = try routines.exercises(for: pull.id)

        let workout = try workouts.startFromRoutine(routineId: pull.id)
        XCTAssertEqual(workout.routineId, pull.id)

        let actualExercises = try workouts.exercises(for: workout.id)
        XCTAssertEqual(
            actualExercises.map(\.exerciseId),
            expectedLinks.map(\.exerciseId)
        )
        XCTAssertEqual(actualExercises.map(\.orderIndex), Array(0..<expectedLinks.count))
    }
}
