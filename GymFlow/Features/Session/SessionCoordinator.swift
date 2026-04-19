import Foundation
import UIKit
import GymFlowCore

@Observable
final class SessionCoordinator {
    struct SessionExercise: Identifiable {
        let workoutExerciseId: UUID
        let exercise: Exercise
        var sets: [SetEntry]
        let previousSets: [SetEntry]

        var id: UUID { workoutExerciseId }
    }

    var workout: Workout
    var exercises: [SessionExercise] = []
    var now: Date = Date()
    var restEndsAt: Date?
    var defaultRestSeconds: Int
    var lastDetectedPRs: [DetectedPR] = []

    private let workoutRepo: WorkoutRepository
    private let exerciseRepo: ExerciseRepository
    private let prCalculator: PRCalculator
    private let analytics: Analytics?
    private var timer: Timer?

    init(
        workout: Workout,
        workoutRepo: WorkoutRepository,
        exerciseRepo: ExerciseRepository,
        prCalculator: PRCalculator,
        defaultRestSeconds: Int = 90,
        analytics: Analytics? = nil
    ) {
        self.workout = workout
        self.workoutRepo = workoutRepo
        self.exerciseRepo = exerciseRepo
        self.prCalculator = prCalculator
        self.defaultRestSeconds = defaultRestSeconds
        self.analytics = analytics
    }

    var elapsed: TimeInterval {
        max(0, now.timeIntervalSince(workout.startedAt))
    }

    var restRemaining: TimeInterval? {
        guard let restEndsAt else { return nil }
        let remaining = restEndsAt.timeIntervalSince(now)
        return remaining > 0 ? remaining : nil
    }

    func loadExistingContents() {
        guard let rows = try? workoutRepo.exercises(for: workout.id) else {
            return
        }
        var loaded: [SessionExercise] = []
        for row in rows {
            guard let ex = (try? exerciseRepo.find(id: row.exerciseId)) ?? nil else { continue }
            let sets = (try? workoutRepo.sets(for: row.id)) ?? []
            let previous = (try? workoutRepo.lastSets(for: ex.id, excludingWorkoutId: workout.id)) ?? []
            loaded.append(SessionExercise(
                workoutExerciseId: row.id,
                exercise: ex,
                sets: sets,
                previousSets: previous
            ))
        }
        exercises = loaded
    }

    func startTicking() {
        stopTicking()
        now = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.now = Date()
                if let restEndsAt = self.restEndsAt, restEndsAt < Date() {
                    self.restEndsAt = nil
                    HapticFeedback.success()
                }
            }
        }
    }

    func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    func addExercise(_ exercise: Exercise) throws {
        let previous = try workoutRepo.lastSets(for: exercise.id, excludingWorkoutId: workout.id)
        let we = try workoutRepo.addExercise(workoutId: workout.id, exerciseId: exercise.id)
        exercises.append(SessionExercise(
            workoutExerciseId: we.id,
            exercise: exercise,
            sets: [],
            previousSets: previous
        ))
        HapticFeedback.impact(.light)
    }

    func logSet(sectionId: UUID, weightKg: Double, reps: Int) throws {
        guard let idx = exercises.firstIndex(where: { $0.workoutExerciseId == sectionId }) else { return }
        let entry = try workoutRepo.addSet(
            workoutExerciseId: sectionId,
            weightKg: weightKg,
            reps: reps
        )
        exercises[idx].sets.append(entry)
        analytics?.log(AnalyticsEventType.setLogged, payload: [
            "exercise_id": exercises[idx].exercise.id.uuidString,
            "reps": "\(reps)",
        ])
        HapticFeedback.success()
        startRest()
    }

    func logCardioSet(sectionId: UUID, durationSec: Int, distanceMeters: Double?) throws {
        guard let idx = exercises.firstIndex(where: { $0.workoutExerciseId == sectionId }) else { return }
        let entry = try workoutRepo.addSet(
            workoutExerciseId: sectionId,
            weightKg: 0,
            reps: 0,
            durationSec: durationSec,
            distanceMeters: distanceMeters
        )
        exercises[idx].sets.append(entry)
        analytics?.log(AnalyticsEventType.setLogged, payload: [
            "exercise_id": exercises[idx].exercise.id.uuidString,
            "duration_sec": "\(durationSec)",
        ])
        HapticFeedback.success()
        startRest()
    }

    func deleteSet(id: UUID) throws {
        try workoutRepo.deleteSet(id: id)
        for i in exercises.indices {
            exercises[i].sets.removeAll { $0.id == id }
        }
        HapticFeedback.impact(.medium)
    }

    func editSet(id: UUID, weightKg: Double, reps: Int) throws {
        try workoutRepo.updateSet(id: id, weightKg: weightKg, reps: reps)
        for i in exercises.indices {
            if let j = exercises[i].sets.firstIndex(where: { $0.id == id }) {
                exercises[i].sets[j].weightKg = weightKg
                exercises[i].sets[j].reps = reps
                exercises[i].sets[j].durationSec = nil
                exercises[i].sets[j].distanceMeters = nil
            }
        }
        HapticFeedback.impact(.light)
    }

    func editCardioSet(id: UUID, durationSec: Int, distanceMeters: Double?) throws {
        try workoutRepo.updateCardioSet(id: id, durationSec: durationSec, distanceMeters: distanceMeters)
        for i in exercises.indices {
            if let j = exercises[i].sets.firstIndex(where: { $0.id == id }) {
                exercises[i].sets[j].weightKg = 0
                exercises[i].sets[j].reps = 0
                exercises[i].sets[j].durationSec = durationSec
                exercises[i].sets[j].distanceMeters = distanceMeters
            }
        }
        HapticFeedback.impact(.light)
    }

    func cancelRest() {
        restEndsAt = nil
    }

    func end() throws {
        let endDate = Date()
        try workoutRepo.end(workoutId: workout.id, at: endDate)
        workout.endedAt = endDate
        lastDetectedPRs = (try? prCalculator.detectAndSave(workoutId: workout.id)) ?? []
        analytics?.log(AnalyticsEventType.workoutEnded, payload: [
            "workout_id": workout.id.uuidString,
            "pr_count": "\(lastDetectedPRs.count)",
            "duration_sec": "\(Int(endDate.timeIntervalSince(workout.startedAt)))",
        ])
        for pr in lastDetectedPRs {
            analytics?.log(AnalyticsEventType.prDetected, payload: [
                "exercise_id": pr.record.exerciseId.uuidString,
                "type": pr.record.type.rawValue,
                "value_kg": String(format: "%.2f", pr.record.valueKg),
            ])
        }
        stopTicking()
        if !lastDetectedPRs.isEmpty {
            HapticFeedback.success()
        }
    }

    private func startRest() {
        restEndsAt = Date().addingTimeInterval(TimeInterval(defaultRestSeconds))
    }
}
