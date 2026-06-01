//
//  DatabaseMigrationTests.swift
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
import GRDB
@testable import GymFlowCore

final class DatabaseMigrationTests: XCTestCase {
    func test_v1Migration_createsAllTables() throws {
        let db = try AppDatabase.inMemory()
        let tables = try db.reader.read { db in
            try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            )
        }
        let expected = [
            "exercise",
            "pr_record",
            "routine",
            "routine_exercise",
            "set_entry",
            "user_settings",
            "workout",
            "workout_exercise"
        ]
        for name in expected {
            XCTAssertTrue(tables.contains(name), "missing table: \(name); got \(tables)")
        }
    }

    func test_foreignKeys_areEnabled() throws {
        let db = try AppDatabase.inMemory()
        let value = try db.reader.read { db in
            try Int.fetchOne(db, sql: "PRAGMA foreign_keys") ?? 0
        }
        XCTAssertEqual(value, 1)
    }
}
