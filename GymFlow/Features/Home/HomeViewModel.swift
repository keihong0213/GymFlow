import Foundation
import GymFlowCore

@Observable
final class HomeViewModel {
    var lastSummary: WorkoutSummary?
    var activeDays: Set<Date> = []

    func load(bootstrap: AppBootstrap, now: Date = Date()) {
        do {
            if let last = try bootstrap.workoutRepo.lastWorkout() {
                lastSummary = try bootstrap.workoutRepo.summary(for: last.id)
            } else {
                lastSummary = nil
            }
            let calendar = Calendar.current
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            let recent = try bootstrap.workoutRepo.workouts(since: sevenDaysAgo)
            activeDays = Set(recent.map { calendar.startOfDay(for: $0.startedAt) })
        } catch {
            lastSummary = nil
            activeDays = []
        }
    }

    func last7Days(now: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today)
        }
    }
}
