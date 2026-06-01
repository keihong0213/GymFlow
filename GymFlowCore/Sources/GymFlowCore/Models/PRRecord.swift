//
//  PRRecord.swift
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

public struct PRRecord: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var exerciseId: UUID
    public var type: PRType
    public var valueKg: Double
    public var weightKg: Double
    public var reps: Int
    public var achievedAt: Date
    public var workoutExerciseId: UUID

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        type: PRType,
        valueKg: Double,
        weightKg: Double,
        reps: Int,
        achievedAt: Date = Date(),
        workoutExerciseId: UUID
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.type = type
        self.valueKg = valueKg
        self.weightKg = weightKg
        self.reps = reps
        self.achievedAt = achievedAt
        self.workoutExerciseId = workoutExerciseId
    }

    public static let databaseTableName = "pr_record"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case type
        case valueKg = "value_kg"
        case weightKg = "weight_kg"
        case reps
        case achievedAt = "achieved_at"
        case workoutExerciseId = "workout_exercise_id"
    }
}
