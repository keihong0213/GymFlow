import XCTest
@testable import GymFlowCore

final class AnalyticsRepositoryTests: XCTestCase {
    private func makeRepo() throws -> AnalyticsRepository {
        let db = try AppDatabase.inMemory()
        return AnalyticsRepository(database: db)
    }

    func test_log_persistsEventAndAppearsInUnsynced() throws {
        let repo = try makeRepo()
        try repo.log(type: "workout_started", payload: ["routine_id": "abc"])

        let events = try repo.unsynced()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, "workout_started")
        XCTAssertEqual(events.first?.payload["routine_id"], "abc")
        XCTAssertNil(events.first?.syncedAt)
    }

func test_markSynced_removesEventsFromUnsynced() throws {
        let repo = try makeRepo()
        try repo.log(type: "a")
        try repo.log(type: "b")
        let initial = try repo.unsynced()
        XCTAssertEqual(initial.count, 2)

        try repo.markSynced(ids: initial.map(\.id))

        XCTAssertTrue(try repo.unsynced().isEmpty, "all events should be marked synced")
    }

    func test_purgeSynced_deletesOnlySyncedRowsOlderThanCutoff() throws {
        let repo = try makeRepo()
        try repo.log(type: "old", at: Date(timeIntervalSince1970: 1_000))
        try repo.log(type: "new", at: Date(timeIntervalSince1970: 2_000))

        let all = try repo.unsynced()
        let oldId = try XCTUnwrap(all.first(where: { $0.eventType == "old" })?.id)
        try repo.markSynced(ids: [oldId], at: Date(timeIntervalSince1970: 1_500))

        try repo.purgeSynced(olderThan: Date(timeIntervalSince1970: 1_600))

        let remaining = try repo.unsynced()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.eventType, "new", "unsynced 'new' row should be preserved")
    }

    func test_payloadRoundTripsAsJson() throws {
        let repo = try makeRepo()
        try repo.log(type: "pr_detected", payload: ["exercise_id": "bench_press", "value_kg": "100.0"])
        let event = try XCTUnwrap(try repo.unsynced().first)
        XCTAssertEqual(event.payload["exercise_id"], "bench_press")
        XCTAssertEqual(event.payload["value_kg"], "100.0")
    }
}
