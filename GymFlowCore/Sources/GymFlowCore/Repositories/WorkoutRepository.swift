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

    @discardableResult
    public func startFromRoutine(routineId: UUID, at date: Date = Date()) throws -> Workout {
        try database.dbWriter.write { db in
            let routineExercises = try RoutineExercise
                .filter(Column("routine_id") == routineId.uuidString)
                .order(Column("order_index"))
                .fetchAll(db)
            guard !routineExercises.isEmpty else {
                throw RoutineRepositoryError.routineHasNoExercises
            }
            let workout = Workout(startedAt: date, routineId: routineId)
            try workout.insert(db)
            for (idx, link) in routineExercises.enumerated() {
                let we = WorkoutExercise(
                    workoutId: workout.id,
                    exerciseId: link.exerciseId,
                    orderIndex: idx
                )
                try we.insert(db)
            }
            return workout
        }
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

    public func exercises(for workoutId: UUID) throws -> [WorkoutExercise] {
        try database.reader.read { db in
            try WorkoutExercise
                .filter(Column("workout_id") == workoutId.uuidString)
                .order(Column("order_index"))
                .fetchAll(db)
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

    public func lastWorkoutExercise(for exerciseId: UUID, excludingWorkoutId: UUID? = nil) throws -> WorkoutExercise? {
        try database.reader.read { db in
            if let excluding = excludingWorkoutId {
                return try WorkoutExercise.fetchOne(
                    db,
                    sql: """
                    SELECT we.*
                    FROM workout_exercise we
                    JOIN workout w ON w.id = we.workout_id
                    WHERE we.exercise_id = ? AND w.id != ?
                    ORDER BY w.started_at DESC
                    LIMIT 1
                    """,
                    arguments: [exerciseId.uuidString, excluding.uuidString]
                )
            }
            return try WorkoutExercise.fetchOne(
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

    public func lastSets(for exerciseId: UUID, excludingWorkoutId: UUID? = nil) throws -> [SetEntry] {
        guard let last = try lastWorkoutExercise(for: exerciseId, excludingWorkoutId: excludingWorkoutId) else { return [] }
        return try sets(for: last.id)
    }

    public func deleteAll() throws {
        try database.dbWriter.write { db in
            _ = try Workout.deleteAll(db)
        }
    }

    @discardableResult
    public func deleteSet(id: UUID) throws -> Bool {
        try database.dbWriter.write { db in
            try SetEntry.deleteOne(db, key: id.uuidString)
        }
    }

    public func updateSet(id: UUID, weightKg: Double, reps: Int) throws {
        try database.dbWriter.write { db in
            if var set = try SetEntry.fetchOne(db, key: id.uuidString) {
                set.weightKg = weightKg
                set.reps = reps
                try set.update(db)
            }
        }
    }

    public func lastWorkout() throws -> Workout? {
        try database.reader.read { db in
            try Workout.order(sql: "started_at DESC").fetchOne(db)
        }
    }

    public func workouts(since date: Date) throws -> [Workout] {
        try database.reader.read { db in
            try Workout
                .filter(Column("started_at") >= date)
                .order(Column("started_at"))
                .fetchAll(db)
        }
    }

    public func summary(for workoutId: UUID) throws -> WorkoutSummary? {
        try database.reader.read { db in
            guard let workout = try Workout.fetchOne(db, key: workoutId) else { return nil }
            let id = workoutId.uuidString
            let exerciseCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM workout_exercise WHERE workout_id = ?",
                arguments: [id]
            ) ?? 0
            let row = try Row.fetchOne(
                db,
                sql: """
                SELECT COUNT(se.id) AS set_count,
                       COALESCE(SUM(se.weight_kg * se.reps), 0.0) AS volume
                FROM set_entry se
                JOIN workout_exercise we ON we.id = se.workout_exercise_id
                WHERE we.workout_id = ?
                """,
                arguments: [id]
            )
            let setCount: Int = row?["set_count"] ?? 0
            let volume: Double = row?["volume"] ?? 0
            return WorkoutSummary(
                workoutId: workoutId,
                startedAt: workout.startedAt,
                endedAt: workout.endedAt,
                exerciseCount: exerciseCount,
                setCount: setCount,
                totalVolumeKg: volume
            )
        }
    }
}
