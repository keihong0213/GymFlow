//
//  RoutineRepository.swift
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

public struct RoutineRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func all() throws -> [Routine] {
        try database.reader.read { db in
            try Routine
                .order(Column("is_built_in").desc, Column("order_index"), Column("created_at"))
                .fetchAll(db)
        }
    }

    public func builtIn() throws -> [Routine] {
        try database.reader.read { db in
            try Routine
                .filter(Column("is_built_in") == true)
                .order(Column("order_index"))
                .fetchAll(db)
        }
    }

    public func custom() throws -> [Routine] {
        try database.reader.read { db in
            try Routine
                .filter(Column("is_built_in") == false)
                .order(Column("created_at"))
                .fetchAll(db)
        }
    }

    public func find(id: UUID) throws -> Routine? {
        try database.reader.read { db in
            try Routine.fetchOne(db, key: id.uuidString)
        }
    }

    public func exercises(for routineId: UUID) throws -> [RoutineExercise] {
        try database.reader.read { db in
            try RoutineExercise
                .filter(Column("routine_id") == routineId.uuidString)
                .order(Column("order_index"))
                .fetchAll(db)
        }
    }

    @discardableResult
    public func createCustom(name: String, exerciseIds: [UUID]) throws -> Routine {
        try database.dbWriter.write { db in
            let routine = Routine(
                name: name,
                slug: nil,
                isBuiltIn: false,
                orderIndex: 0,
                createdAt: Date()
            )
            try routine.insert(db)
            for (idx, exerciseId) in exerciseIds.enumerated() {
                let link = RoutineExercise(
                    routineId: routine.id,
                    exerciseId: exerciseId,
                    orderIndex: idx
                )
                try link.insert(db)
            }
            return routine
        }
    }

    public func updateCustom(id: UUID, name: String, exerciseIds: [UUID]) throws {
        try database.dbWriter.write { db in
            guard var routine = try Routine.fetchOne(db, key: id.uuidString) else {
                throw RoutineRepositoryError.notFound
            }
            guard !routine.isBuiltIn else {
                throw RoutineRepositoryError.builtInNotEditable
            }
            routine.name = name
            try routine.update(db)
            _ = try RoutineExercise
                .filter(Column("routine_id") == id.uuidString)
                .deleteAll(db)
            for (idx, exerciseId) in exerciseIds.enumerated() {
                let link = RoutineExercise(
                    routineId: id,
                    exerciseId: exerciseId,
                    orderIndex: idx
                )
                try link.insert(db)
            }
        }
    }

    @discardableResult
    public func delete(id: UUID) throws -> Bool {
        try database.dbWriter.write { db in
            guard let routine = try Routine.fetchOne(db, key: id.uuidString), !routine.isBuiltIn else {
                return false
            }
            return try Routine.deleteOne(db, key: id.uuidString)
        }
    }
}

public enum RoutineRepositoryError: Error, Sendable {
    case notFound
    case builtInNotEditable
    case routineHasNoExercises
}
