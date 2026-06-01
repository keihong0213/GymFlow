//
//  PRRepository.swift
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

public struct PRRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func currentPRs(for exerciseId: UUID) throws -> [PRRecord] {
        try database.reader.read { db in
            var best: [PRType: PRRecord] = [:]
            let all = try PRRecord
                .filter(Column("exercise_id") == exerciseId.uuidString)
                .order(Column("value_kg").desc, Column("achieved_at").desc)
                .fetchAll(db)
            for record in all {
                if best[record.type] == nil {
                    best[record.type] = record
                }
            }
            return PRType.allCases.compactMap { best[$0] }
        }
    }

    public func allPRs(for exerciseId: UUID) throws -> [PRRecord] {
        try database.reader.read { db in
            try PRRecord
                .filter(Column("exercise_id") == exerciseId.uuidString)
                .order(Column("achieved_at"))
                .fetchAll(db)
        }
    }
}
