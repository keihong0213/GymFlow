//
//  Routine.swift
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

public struct Routine: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var name: String
    public var slug: String?
    public var isBuiltIn: Bool
    public var orderIndex: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        slug: String? = nil,
        isBuiltIn: Bool = false,
        orderIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.isBuiltIn = isBuiltIn
        self.orderIndex = orderIndex
        self.createdAt = createdAt
    }

    public static let databaseTableName = "routine"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case isBuiltIn = "is_built_in"
        case orderIndex = "order_index"
        case createdAt = "created_at"
    }
}

public struct RoutineExercise: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var routineId: UUID
    public var exerciseId: UUID
    public var orderIndex: Int
    public var targetSets: Int?
    public var targetRepsMin: Int?
    public var targetRepsMax: Int?
    public var defaultRestSeconds: Int?

    public init(
        id: UUID = UUID(),
        routineId: UUID,
        exerciseId: UUID,
        orderIndex: Int,
        targetSets: Int? = nil,
        targetRepsMin: Int? = nil,
        targetRepsMax: Int? = nil,
        defaultRestSeconds: Int? = nil
    ) {
        self.id = id
        self.routineId = routineId
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.defaultRestSeconds = defaultRestSeconds
    }

    public static let databaseTableName = "routine_exercise"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case routineId = "routine_id"
        case exerciseId = "exercise_id"
        case orderIndex = "order_index"
        case targetSets = "target_sets"
        case targetRepsMin = "target_reps_min"
        case targetRepsMax = "target_reps_max"
        case defaultRestSeconds = "default_rest_seconds"
    }
}
