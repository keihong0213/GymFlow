import Foundation
import GymFlowCore

@Observable
final class Analytics {
    private let repository: AnalyticsRepository

    init(repository: AnalyticsRepository) {
        self.repository = repository
    }

    func log(_ eventType: String, payload: [String: String] = [:]) {
        do {
            try repository.log(type: eventType, payload: payload)
            #if DEBUG
            print("[analytics] \(eventType) \(payload)")
            #endif
        } catch {
            #if DEBUG
            print("[analytics] failed to log \(eventType): \(error)")
            #endif
        }
    }
}

enum AnalyticsEventType {
    static let workoutStarted = "workout_started"
    static let workoutEnded = "workout_ended"
    static let setLogged = "set_logged"
    static let prDetected = "pr_detected"
}
