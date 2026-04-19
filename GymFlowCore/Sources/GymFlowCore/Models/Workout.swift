import Foundation
import GRDB

public struct Workout: Identifiable, Codable, Equatable, Hashable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var routineId: UUID?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        routineId: UUID? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.routineId = routineId
        self.notes = notes
    }

    public static let databaseTableName = "workout"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case routineId = "routine_id"
        case notes
    }
}

public struct WorkoutExercise: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var workoutId: UUID
    public var exerciseId: UUID
    public var orderIndex: Int
    public var notes: String?

    public init(
        id: UUID = UUID(),
        workoutId: UUID,
        exerciseId: UUID,
        orderIndex: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
        self.notes = notes
    }

    public static let databaseTableName = "workout_exercise"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case workoutId = "workout_id"
        case exerciseId = "exercise_id"
        case orderIndex = "order_index"
        case notes
    }
}

public struct SetEntry: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var workoutExerciseId: UUID
    public var setNumber: Int
    public var weightKg: Double
    public var reps: Int
    public var isWarmup: Bool
    public var rpe: Double?
    public var completedAt: Date
    public var durationSec: Int?
    public var distanceMeters: Double?

    public init(
        id: UUID = UUID(),
        workoutExerciseId: UUID,
        setNumber: Int,
        weightKg: Double,
        reps: Int,
        isWarmup: Bool = false,
        rpe: Double? = nil,
        completedAt: Date = Date(),
        durationSec: Int? = nil,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.workoutExerciseId = workoutExerciseId
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.isWarmup = isWarmup
        self.rpe = rpe
        self.completedAt = completedAt
        self.durationSec = durationSec
        self.distanceMeters = distanceMeters
    }

    public var volumeKg: Double { weightKg * Double(reps) }

    public var estimatedOneRepMaxKg: Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }

    public static let databaseTableName = "set_entry"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case workoutExerciseId = "workout_exercise_id"
        case setNumber = "set_number"
        case weightKg = "weight_kg"
        case reps
        case isWarmup = "is_warmup"
        case rpe
        case completedAt = "completed_at"
        case durationSec = "duration_sec"
        case distanceMeters = "distance_meters"
    }
}
