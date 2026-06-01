//
//  SetEntryTests.swift
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

final class SetEntryTests: XCTestCase {
    func test_volumeKg_multipliesWeightAndReps() {
        let set = SetEntry(workoutExerciseId: UUID(), setNumber: 1, weightKg: 80, reps: 5)
        XCTAssertEqual(set.volumeKg, 400)
    }

    func test_e1rm_oneRepReturnsWeight() {
        let set = SetEntry(workoutExerciseId: UUID(), setNumber: 1, weightKg: 100, reps: 1)
        XCTAssertEqual(set.estimatedOneRepMaxKg, 100)
    }

    func test_e1rm_epleyFormula() {
        let set = SetEntry(workoutExerciseId: UUID(), setNumber: 1, weightKg: 100, reps: 10)
        XCTAssertEqual(set.estimatedOneRepMaxKg, 100 * (1 + 10.0/30.0), accuracy: 1e-9)
    }

    func test_e1rm_zeroRepsReturnsZero() {
        let set = SetEntry(workoutExerciseId: UUID(), setNumber: 1, weightKg: 100, reps: 0)
        XCTAssertEqual(set.estimatedOneRepMaxKg, 0)
    }
}
