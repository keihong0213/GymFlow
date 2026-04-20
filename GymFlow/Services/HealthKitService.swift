import Foundation
import HealthKit
import GymFlowCore

@Observable
final class HealthKitService {
    enum AuthStatus {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    private let store = HKHealthStore()
    var status: AuthStatus = HKHealthStore.isHealthDataAvailable() ? .notDetermined : .unavailable

    func requestAuthorization() async -> AuthStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = .unavailable
            return .unavailable
        }
        let types: Set<HKSampleType> = [HKObjectType.workoutType()]
        do {
            try await store.requestAuthorization(toShare: types, read: [])
            // HealthKit doesn't give a read-back; treat as authorized unless save throws.
            status = .authorized
            return .authorized
        } catch {
            status = .denied
            return .denied
        }
    }

    /// Fire-and-forget save. Returns true if the save attempt completed without error.
    @discardableResult
    func save(
        startedAt: Date,
        endedAt: Date,
        primaryCategory: ExerciseCategory,
        dominantCardioExercise: String?
    ) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              endedAt > startedAt else { return false }
        let workout = HKWorkout(
            activityType: Self.activityType(for: primaryCategory, cardioSlug: dominantCardioExercise),
            start: startedAt,
            end: endedAt
        )
        do {
            try await store.save(workout)
            return true
        } catch {
            return false
        }
    }

    private static func activityType(
        for category: ExerciseCategory,
        cardioSlug: String?
    ) -> HKWorkoutActivityType {
        switch category {
        case .barbell, .dumbbell, .machine:
            return .traditionalStrengthTraining
        case .bodyweight:
            return .functionalStrengthTraining
        case .cardio:
            guard let slug = cardioSlug else { return .other }
            switch slug {
            case "treadmill": return .running
            case "stationary_bike": return .cycling
            case "rowing_machine": return .rowing
            case "elliptical": return .elliptical
            case "stairmaster": return .stairClimbing
            case "jump_rope": return .jumpRope
            default: return .other
            }
        case .other:
            return .other
        }
    }
}
