//
//  ExerciseRepositoryTests.swift
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
