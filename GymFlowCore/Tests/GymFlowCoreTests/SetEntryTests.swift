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
