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
        at date: Date = Date(),
        durationSec: Int? = nil,
        distanceMeters: Double? = nil
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
                completedAt: date,
                durationSec: durationSec,
                distanceMeters: distanceMeters
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
    public func deleteWorkout(id: UUID) throws -> Bool {
        try database.dbWriter.write { db in
            try Workout.deleteOne(db, key: id.uuidString)
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
                set.durationSec = nil
                set.distanceMeters = nil
                try set.update(db)
            }
        }
    }

    public func updateCardioSet(id: UUID, durationSec: Int, distanceMeters: Double?) throws {
        try database.dbWriter.write { db in
            if var set = try SetEntry.fetchOne(db, key: id.uuidString) {
                set.weightKg = 0
                set.reps = 0
                set.durationSec = durationSec
                set.distanceMeters = distanceMeters
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

    public func completedWorkouts(limit: Int? = nil) throws -> [Workout] {
        try database.reader.read { db in
            var request = Workout
                .filter(Column("ended_at") != nil)
                .order(Column("started_at").desc)
            if let limit {
                request = request.limit(limit)
            }
            return try request.fetchAll(db)
        }
    }

    public func completedWorkouts(in interval: DateInterval) throws -> [Workout] {
        try database.reader.read { db in
            try Workout
                .filter(Column("ended_at") != nil)
                .filter(Column("started_at") >= interval.start)
                .filter(Column("started_at") < interval.end)
                .order(Column("started_at"))
                .fetchAll(db)
        }
    }

    public func completedWorkout(on day: Date, calendar: Calendar = .current) throws -> Workout? {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        return try database.reader.read { db in
            try Workout
                .filter(Column("ended_at") != nil)
                .filter(Column("started_at") >= start)
                .filter(Column("started_at") < end)
                .order(Column("started_at").desc)
                .fetchOne(db)
        }
    }

    public func history(for exerciseId: UUID, limit: Int = 10) throws -> [ExerciseHistoryEntry] {
        try database.reader.read { db in
            let workoutRows = try Row.fetchAll(
                db,
                sql: """
                SELECT w.id AS w_id, w.started_at, w.ended_at
                FROM workout w
                WHERE EXISTS (
                    SELECT 1 FROM workout_exercise we
                    JOIN set_entry s ON s.workout_exercise_id = we.id
                    WHERE we.workout_id = w.id
                      AND we.exercise_id = ?
                      AND s.is_warmup = 0
                )
                ORDER BY w.started_at DESC
                LIMIT ?
                """,
                arguments: [exerciseId.uuidString, limit]
            )
            var entries: [ExerciseHistoryEntry] = []
            for row in workoutRows {
                guard let workoutIdString: String = row["w_id"],
                      let workoutId = UUID(uuidString: workoutIdString),
                      let startedAt: Date = row["started_at"] else { continue }
                let endedAt: Date? = row["ended_at"]
                let sets = try SetEntry.fetchAll(
                    db,
                    sql: """
                    SELECT s.* FROM set_entry s
                    JOIN workout_exercise we ON we.id = s.workout_exercise_id
                    WHERE we.workout_id = ?
                      AND we.exercise_id = ?
                      AND s.is_warmup = 0
                    """,
                    arguments: [workoutIdString, exerciseId.uuidString]
                )
                let top = sets.max(by: { $0.estimatedOneRepMaxKg < $1.estimatedOneRepMaxKg })
                let volume = sets.reduce(0.0) { $0 + $1.volumeKg }
                entries.append(ExerciseHistoryEntry(
                    id: workoutId,
                    workoutId: workoutId,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    topSet: top,
                    totalVolumeKg: volume,
                    setCount: sets.count
                ))
            }
            return entries
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
