//
//  DemoDataSeeder.swift
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

#if DEBUG
import Foundation
import GymFlowCore

enum DemoDataSeeder {
    static func seed(bootstrap: AppBootstrap, now: Date = Date()) throws {
        let exercises = bootstrap.exerciseRepo
        let workouts = bootstrap.workoutRepo
        let calendar = Calendar.current

        guard let bench = try exercises.find(slug: "bench_press"),
              let squat = try exercises.find(slug: "back_squat"),
              let deadlift = try exercises.find(slug: "deadlift"),
              let pullUp = try exercises.find(slug: "pull_up") else { return }

        func addWorkout(daysAgo: Int, durationMinutes: Int, _ build: (UUID) throws -> Void) throws {
            guard let start = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return }
            let workout = try workouts.start(at: start)
            try build(workout.id)
            try workouts.end(workoutId: workout.id, at: start.addingTimeInterval(Double(durationMinutes) * 60))
        }

        try addWorkout(daysAgo: 5, durationMinutes: 55) { workoutId in
            let we = try workouts.addExercise(workoutId: workoutId, exerciseId: bench.id)
            for r in [10, 9, 8, 7] {
                _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 75, reps: r)
            }
            let we2 = try workouts.addExercise(workoutId: workoutId, exerciseId: pullUp.id)
            for r in [8, 7, 6] {
                _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 0, reps: r)
            }
        }

        try addWorkout(daysAgo: 3, durationMinutes: 48) { workoutId in
            let we = try workouts.addExercise(workoutId: workoutId, exerciseId: squat.id)
            for r in [8, 8, 6] {
                _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 100, reps: r)
            }
            let we2 = try workouts.addExercise(workoutId: workoutId, exerciseId: deadlift.id)
            for r in [5, 5, 5] {
                _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 120, reps: r)
            }
        }

        try addWorkout(daysAgo: 1, durationMinutes: 62) { workoutId in
            let we = try workouts.addExercise(workoutId: workoutId, exerciseId: bench.id)
            for r in [10, 10, 9, 8] {
                _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 77.5, reps: r)
            }
            let we2 = try workouts.addExercise(workoutId: workoutId, exerciseId: pullUp.id)
            for r in [9, 8, 7] {
                _ = try workouts.addSet(workoutExerciseId: we2.id, weightKg: 0, reps: r)
            }
        }
    }

    static func clearWorkouts(bootstrap: AppBootstrap) throws {
        try bootstrap.workoutRepo.deleteAll()
    }

    @discardableResult
    static func seedFinishedSession(bootstrap: AppBootstrap, now: Date = Date()) throws -> (Workout, [DetectedPR]) {
        let exercises = bootstrap.exerciseRepo
        let workouts = bootstrap.workoutRepo
        let startedAt = now.addingTimeInterval(-47 * 60)
        let endedAt = now

        let workout = try workouts.start(at: startedAt)

        if let bench = try exercises.find(slug: "bench_press") {
            let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 80, reps: 10)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 80, reps: 9)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 82.5, reps: 8)
        }
        if let squat = try exercises.find(slug: "back_squat") {
            let we = try workouts.addExercise(workoutId: workout.id, exerciseId: squat.id)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 105, reps: 6)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 105, reps: 6)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 105, reps: 5)
        }

        try workouts.end(workoutId: workout.id, at: endedAt)
        var ended = workout
        ended.endedAt = endedAt
        let prs = try bootstrap.prCalculator.detectAndSave(workoutId: workout.id)
        return (ended, prs)
    }

    @discardableResult
    static func seedActiveSession(bootstrap: AppBootstrap, now: Date = Date()) throws -> Workout {
        let exercises = bootstrap.exerciseRepo
        let workouts = bootstrap.workoutRepo
        let startedAt = now.addingTimeInterval(-25 * 60)

        let workout = try workouts.start(at: startedAt)

        if let bench = try exercises.find(slug: "bench_press") {
            let we = try workouts.addExercise(workoutId: workout.id, exerciseId: bench.id)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 75, reps: 10)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 75, reps: 9)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 77.5, reps: 8)
        }

        if let row = try exercises.find(slug: "barbell_row") {
            let we = try workouts.addExercise(workoutId: workout.id, exerciseId: row.id)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 10)
            _ = try workouts.addSet(workoutExerciseId: we.id, weightKg: 60, reps: 8)
        }

        return workout
    }
}
#endif
