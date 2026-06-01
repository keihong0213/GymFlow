//
//  WeightFormatterTests.swift
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

final class WeightFormatterTests: XCTestCase {
    func test_kg_preservesValue() {
        let f = WeightFormatter(unit: .kg, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(f.format(kg: 85), "85 kg")
        XCTAssertEqual(f.format(kg: 82.5), "82.5 kg")
    }

    func test_lb_converts() {
        let f = WeightFormatter(unit: .lb, locale: Locale(identifier: "en_US"))
        let out = f.format(kg: 100)
        XCTAssertTrue(out.hasSuffix(" lb"))
        XCTAssertTrue(out.contains("220"), "got \(out)")
    }

    func test_locale_ja_usesSameSymbols() {
        let f = WeightFormatter(unit: .kg, locale: Locale(identifier: "ja_JP"))
        XCTAssertTrue(f.format(kg: 85).hasSuffix(" kg"))
    }

    func test_step_matchesUnit() {
        XCTAssertEqual(WeightUnit.kg.step, 2.5)
        XCTAssertEqual(WeightUnit.lb.step, 5)
    }

    func test_roundtrip_conversion() {
        let kg = 100.0
        let lb = WeightUnit.lb.fromKg(kg)
        let back = WeightUnit.lb.toKg(lb)
        XCTAssertEqual(back, kg, accuracy: 1e-9)
    }
}
