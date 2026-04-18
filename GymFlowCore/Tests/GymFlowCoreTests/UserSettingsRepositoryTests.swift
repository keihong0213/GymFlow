import XCTest
@testable import GymFlowCore

final class UserSettingsRepositoryTests: XCTestCase {
    private func makeRepo() throws -> UserSettingsRepository {
        let db = try AppDatabase.inMemory()
        return UserSettingsRepository(database: db)
    }

    func test_load_returnsDefaultsOnFirstRun_andSeedsSingleton() throws {
        let repo = try makeRepo()
        let first = try repo.load()
        XCTAssertEqual(first.id, UserSettings.singletonId)
        XCTAssertEqual(first.units, .kg)
        XCTAssertEqual(first.language, .system)
        XCTAssertEqual(first.defaultRestSeconds, 90)
        XCTAssertEqual(first.appearance, .system)

        // Second load must return the same row, not create a new one.
        let second = try repo.load()
        XCTAssertEqual(first, second)
    }

    func test_save_persistsAndReloads() throws {
        let repo = try makeRepo()
        _ = try repo.load()
        let updated = UserSettings(units: .lb, language: .ja, defaultRestSeconds: 120, appearance: .dark)
        try repo.save(updated)

        let reloaded = try repo.load()
        XCTAssertEqual(reloaded.units, .lb)
        XCTAssertEqual(reloaded.language, .ja)
        XCTAssertEqual(reloaded.defaultRestSeconds, 120)
        XCTAssertEqual(reloaded.appearance, .dark)
    }

    func test_save_beforeLoad_stillEnforcesSingleton() throws {
        let repo = try makeRepo()
        // Save without ever calling load() — repo must coerce id to singletonId.
        let direct = UserSettings(id: 42, units: .lb, language: .en, defaultRestSeconds: 60, appearance: .light)
        try repo.save(direct)

        let reloaded = try repo.load()
        XCTAssertEqual(reloaded.id, UserSettings.singletonId)
        XCTAssertEqual(reloaded.units, .lb)
        XCTAssertEqual(reloaded.language, .en)
    }
}
