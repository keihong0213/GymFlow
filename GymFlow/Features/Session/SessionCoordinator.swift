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
    var defaultRestSeconds: Int = 90

    private let workoutRepo: WorkoutRepository
    private let exerciseRepo: ExerciseRepository
    private var timer: Timer?

    init(workout: Workout, workoutRepo: WorkoutRepository, exerciseRepo: ExerciseRepository) {
        self.workout = workout
        self.workoutRepo = workoutRepo
        self.exerciseRepo = exerciseRepo
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
                self?.now = Date()
                if let restEndsAt = self?.restEndsAt, restEndsAt < Date() {
                    self?.restEndsAt = nil
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
    }

    func logSet(sectionId: UUID, weightKg: Double, reps: Int) throws {
        guard let idx = exercises.firstIndex(where: { $0.workoutExerciseId == sectionId }) else { return }
        let entry = try workoutRepo.addSet(
            workoutExerciseId: sectionId,
            weightKg: weightKg,
            reps: reps
        )
        exercises[idx].sets.append(entry)
        haptic(.success)
        startRest()
    }

    func deleteSet(id: UUID) throws {
        try workoutRepo.deleteSet(id: id)
        for i in exercises.indices {
            exercises[i].sets.removeAll { $0.id == id }
        }
    }

    func cancelRest() {
        restEndsAt = nil
    }

    func end() throws {
        try workoutRepo.end(workoutId: workout.id)
        stopTicking()
    }

    private func startRest() {
        restEndsAt = Date().addingTimeInterval(TimeInterval(defaultRestSeconds))
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(type)
    }
}
