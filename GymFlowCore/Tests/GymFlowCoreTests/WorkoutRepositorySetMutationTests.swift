//
//  WorkoutRepositorySetMutationTests.swift
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
