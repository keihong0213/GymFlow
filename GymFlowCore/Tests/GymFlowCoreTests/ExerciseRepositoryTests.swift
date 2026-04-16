import XCTest
@testable import GymFlowCore

final class ExerciseRepositoryTests: XCTestCase {
    func test_createCustom_and_find() throws {
        let db = try AppDatabase.inMemory()
        let repo = ExerciseRepository(database: db)

        let ex = try repo.createCustom(name: "我的動作", category: .machine)
        XCTAssertTrue(ex.isCustom)
        XCTAssertEqual(ex.customName, "我的動作")
        XCTAssertEqual(ex.category, .machine)

        let fetched = try XCTUnwrap(try repo.find(id: ex.id))
        XCTAssertEqual(fetched.id, ex.id)
        XCTAssertEqual(fetched.slug, ex.slug)
        XCTAssertEqual(fetched.category, ex.category)
        XCTAssertEqual(fetched.isCustom, ex.isCustom)
        XCTAssertEqual(fetched.customName, ex.customName)
    }

    func test_byCategory_filters() throws {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let repo = ExerciseRepository(database: db)

        let barbell = try repo.byCategory(.barbell)
        XCTAssertTrue(barbell.allSatisfy { $0.category == .barbell })
        XCTAssertFalse(barbell.isEmpty)
    }

    func test_findBySlug_returnsExpected() throws {
        let db = try AppDatabase.inMemory()
        try ExerciseSeedLoader.seed(into: db)
        let repo = ExerciseRepository(database: db)

        let bench = try repo.find(slug: "bench_press")
        XCTAssertNotNil(bench)
        XCTAssertEqual(bench?.category, .barbell)
    }
}
