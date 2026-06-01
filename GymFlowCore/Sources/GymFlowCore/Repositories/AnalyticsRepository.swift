//
//  AnalyticsRepository.swift
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

public struct AnalyticsRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func log(
        type: String,
        payload: [String: String] = [:],
        at date: Date = Date()
    ) throws {
        let event = AnalyticsEvent(
            id: UUID(),
            occurredAt: date,
            eventType: type,
            payload: payload
        )
        try database.dbWriter.write { db in
            try event.insert(db)
        }
    }

    public func unsynced(limit: Int = 500) throws -> [AnalyticsEvent] {
        try database.reader.read { db in
            try AnalyticsEvent
                .filter(Column("synced_at") == nil)
                .order(Column("occurred_at"))
                .limit(limit)
                .fetchAll(db)
        }
    }

    public func markSynced(ids: [UUID], at date: Date = Date()) throws {
        guard !ids.isEmpty else { return }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        var arguments: [DatabaseValueConvertible] = [date]
        arguments.append(contentsOf: ids.map(\.uuidString))
        try database.dbWriter.write { db in
            try db.execute(
                sql: "UPDATE analytics_event SET synced_at = ? WHERE id IN (\(placeholders))",
                arguments: StatementArguments(arguments)
            )
        }
    }

    public func purgeSynced(olderThan date: Date) throws {
        _ = try database.dbWriter.write { db in
            try db.execute(
                sql: "DELETE FROM analytics_event WHERE synced_at IS NOT NULL AND synced_at < ?",
                arguments: [date]
            )
        }
    }
}
