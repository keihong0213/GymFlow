import Foundation
import GRDB

public struct WorkoutRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    @discardableResult
    public func start(routineId: UUID? = nil, at date: Date = Date()) throws -> Workout {
        let workout = Workout(startedAt: date, routineId: routineId)
        try database.dbWriter.write { db in
            try workout.insert(db)
        }
        return workout
    }

    public func end(workoutId: UUID, at date: Date = Date()) throws {
        try database.dbWriter.write { db in
            if var workout = try Workout.fetchOne(db, key: workoutId.uuidString) {
                workout.endedAt = date
                try workout.update(db)
            }
        }
    }

    @discardableResult
    public func addExercise(workoutId: UUID, exerciseId: UUID) throws -> WorkoutExercise {
        try database.dbWriter.write { db in
            let nextOrder = try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(MAX(order_index), -1) + 1 FROM workout_exercise WHERE workout_id = ?",
                arguments: [workoutId.uuidString]
            ) ?? 0
            let row = WorkoutExercise(
                workoutId: workoutId,
                exerciseId: exerciseId,
                orderIndex: nextOrder
            )
            try row.insert(db)
            return row
        }
    }

    @discardableResult
    public func addSet(
        workoutExerciseId: UUID,
        weightKg: Double,
        reps: Int,
        isWarmup: Bool = false,
        rpe: Double? = nil,
        at date: Date = Date()
    ) throws -> SetEntry {
        try database.dbWriter.write { db in
            let nextSet = try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(MAX(set_number), 0) + 1 FROM set_entry WHERE workout_exercise_id = ?",
                arguments: [workoutExerciseId.uuidString]
            ) ?? 1
            let entry = SetEntry(
                workoutExerciseId: workoutExerciseId,
                setNumber: nextSet,
                weightKg: weightKg,
                reps: reps,
                isWarmup: isWarmup,
                rpe: rpe,
                completedAt: date
            )
            try entry.insert(db)
            return entry
        }
    }

    public func sets(for workoutExerciseId: UUID) throws -> [SetEntry] {
        try database.reader.read { db in
            try SetEntry
                .filter(Column("workout_exercise_id") == workoutExerciseId.uuidString)
                .order(Column("set_number"))
                .fetchAll(db)
        }
    }

    public func lastWorkoutExercise(for exerciseId: UUID) throws -> WorkoutExercise? {
        try database.reader.read { db in
            try WorkoutExercise.fetchOne(
                db,
                sql: """
                SELECT we.*
                FROM workout_exercise we
                JOIN workout w ON w.id = we.workout_id
                WHERE we.exercise_id = ?
                ORDER BY w.started_at DESC
                LIMIT 1
                """,
                arguments: [exerciseId.uuidString]
            )
        }
    }

    public func lastSets(for exerciseId: UUID) throws -> [SetEntry] {
        guard let last = try lastWorkoutExercise(for: exerciseId) else { return [] }
        return try sets(for: last.id)
    }
}
