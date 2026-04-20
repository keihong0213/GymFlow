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

    private var workoutAuthIsDenied: Bool {
        store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingDenied
    }

    func requestAuthorization() async -> AuthStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run { status = .unavailable }
            return .unavailable
        }
        let types: Set<HKSampleType> = [HKObjectType.workoutType()]
        do {
            try await store.requestAuthorization(toShare: types, read: [])
        } catch {
            await MainActor.run { status = .denied }
            return .denied
        }
        // The request call doesn't itself tell us yes/no; query authorization status.
        let denied = workoutAuthIsDenied
        let resolved: AuthStatus = denied ? .denied : .authorized
        await MainActor.run { status = resolved }
        return resolved
    }

    /// Writes an HKWorkout to HealthKit. Returns true on success.
    /// On failure, updates `status` (denied if the permission is clearly revoked,
    /// otherwise leaves it unchanged so transient errors don't flip the UI).
    @discardableResult
    func save(
        startedAt: Date,
        endedAt: Date,
        primaryCategory: ExerciseCategory,
        dominantCardioExercise: String?
    ) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run { status = .unavailable }
            return false
        }
        guard endedAt > startedAt else { return false }
        let workout = HKWorkout(
            activityType: Self.activityType(for: primaryCategory, cardioSlug: dominantCardioExercise),
            start: startedAt,
            end: endedAt
        )
        do {
            try await store.save(workout)
            await MainActor.run { status = .authorized }
            return true
        } catch {
            if workoutAuthIsDenied {
                await MainActor.run { status = .denied }
            }
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
