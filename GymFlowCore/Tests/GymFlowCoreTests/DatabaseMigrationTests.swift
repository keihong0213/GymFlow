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
