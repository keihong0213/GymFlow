import XCTest
@testable import GymFlowCore

final class ExerciseSeedLoaderTests: XCTestCase {
    func test_loadBundled_parsesPayload() throws {
        let payload = try ExerciseSeedLoader.loadBundled()
        XCTAssertEqual(payload.version, 1)
        XCTAssertGreaterThanOrEqual(payload.exercises.count, 60)
        for item in payload.exercises {
            for lang in ["zh-Hant", "zh-Hans", "en", "ja", "ko"] {
                XCTAssertNotNil(
                    item.names[lang],
                    "exercise \(item.slug) missing \(lang) name"
                )
            }
        }
    }

    func test_seed_isIdempotent() throws {
        let db = try AppDatabase.inMemory()
        let first = try ExerciseSeedLoader.seed(into: db)
        let second = try ExerciseSeedLoader.seed(into: db)
        XCTAssertGreaterThan(first.inserted, 0)
        XCTAssertEqual(first.updated, 0)
        XCTAssertEqual(second.inserted, 0)
        XCTAssertEqual(second.updated, 0)

        let repo = ExerciseRepository(database: db)
        let all = try repo.all()
        XCTAssertEqual(all.count, first.inserted)
    }

    func test_seed_hasNoDuplicateSlugs() throws {
        let payload = try ExerciseSeedLoader.loadBundled()
        let slugs = payload.exercises.map(\.slug)
        XCTAssertEqual(slugs.count, Set(slugs).count, "duplicate slugs in seed")
    }
}
