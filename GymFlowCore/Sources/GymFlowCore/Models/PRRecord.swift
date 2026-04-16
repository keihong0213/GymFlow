import Foundation
import GRDB

public struct PRRecord: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var exerciseId: UUID
    public var type: PRType
    public var valueKg: Double
    public var weightKg: Double
    public var reps: Int
    public var achievedAt: Date
    public var workoutExerciseId: UUID

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        type: PRType,
        valueKg: Double,
        weightKg: Double,
        reps: Int,
        achievedAt: Date = Date(),
        workoutExerciseId: UUID
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.type = type
        self.valueKg = valueKg
        self.weightKg = weightKg
        self.reps = reps
        self.achievedAt = achievedAt
        self.workoutExerciseId = workoutExerciseId
    }

    public static let databaseTableName = "pr_record"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case type
        case valueKg = "value_kg"
        case weightKg = "weight_kg"
        case reps
        case achievedAt = "achieved_at"
        case workoutExerciseId = "workout_exercise_id"
    }
}
