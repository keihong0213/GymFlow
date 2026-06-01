//
//  PRCalculator.swift
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

import Foundation
import GRDB

public struct DetectedPR: Equatable, Sendable {
    public let record: PRRecord
    public let previousValueKg: Double?

    public var isFirst: Bool { previousValueKg == nil }
}

public struct PRCalculator: Sendable {
    public let database: AppDatabase

    static let prEpsilon: Double = 0.001

    public init(database: AppDatabase) {
        self.database = database
    }

    public func detectAndSave(workoutId: UUID) throws -> [DetectedPR] {
        try database.dbWriter.write { db in
            let workoutExercises = try WorkoutExercise
                .filter(Column("workout_id") == workoutId.uuidString)
                .fetchAll(db)

            var detected: [DetectedPR] = []
            for we in workoutExercises {
                let sets = try SetEntry
                    .filter(Column("workout_exercise_id") == we.id.uuidString)
                    .filter(Column("is_warmup") == false)
                    .filter(Column("reps") >= 1)
                    .fetchAll(db)
                guard !sets.isEmpty else { continue }

                if let weightPR = try evaluateWeightPR(for: we, sets: sets, db: db) {
                    try weightPR.record.insert(db)
                    detected.append(weightPR)
                }
                if let e1rmPR = try evaluateE1RMPR(for: we, sets: sets, db: db) {
                    try e1rmPR.record.insert(db)
                    detected.append(e1rmPR)
                }
            }
            return detected
        }
    }

    private func evaluateWeightPR(
        for we: WorkoutExercise,
        sets: [SetEntry],
        db: Database
    ) throws -> DetectedPR? {
        guard let best = sets.max(by: { $0.weightKg < $1.weightKg }) else { return nil }
        let existing = try PRRecord
            .filter(Column("exercise_id") == we.exerciseId.uuidString)
            .filter(Column("type") == PRType.weight.rawValue)
            .order(Column("value_kg").desc)
            .fetchOne(db)
        if let existing, best.weightKg <= existing.valueKg + Self.prEpsilon { return nil }
        let record = PRRecord(
            exerciseId: we.exerciseId,
            type: .weight,
            valueKg: best.weightKg,
            weightKg: best.weightKg,
            reps: best.reps,
            achievedAt: best.completedAt,
            workoutExerciseId: we.id
        )
        return DetectedPR(record: record, previousValueKg: existing?.valueKg)
    }

    private func evaluateE1RMPR(
        for we: WorkoutExercise,
        sets: [SetEntry],
        db: Database
    ) throws -> DetectedPR? {
        guard let best = sets.max(by: { $0.estimatedOneRepMaxKg < $1.estimatedOneRepMaxKg }) else { return nil }
        let e1rm = best.estimatedOneRepMaxKg
        let existing = try PRRecord
            .filter(Column("exercise_id") == we.exerciseId.uuidString)
            .filter(Column("type") == PRType.e1rm.rawValue)
            .order(Column("value_kg").desc)
            .fetchOne(db)
        if let existing, e1rm <= existing.valueKg + Self.prEpsilon { return nil }
        let record = PRRecord(
            exerciseId: we.exerciseId,
            type: .e1rm,
            valueKg: e1rm,
            weightKg: best.weightKg,
            reps: best.reps,
            achievedAt: best.completedAt,
            workoutExerciseId: we.id
        )
        return DetectedPR(record: record, previousValueKg: existing?.valueKg)
    }
}
