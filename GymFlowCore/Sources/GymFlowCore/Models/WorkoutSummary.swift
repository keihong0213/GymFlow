import Foundation

public struct WorkoutSummary: Identifiable, Equatable, Sendable {
    public let workoutId: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let exerciseCount: Int
    public let setCount: Int
    public let totalVolumeKg: Double

    public init(
        workoutId: UUID,
        startedAt: Date,
        endedAt: Date?,
        exerciseCount: Int,
        setCount: Int,
        totalVolumeKg: Double
    ) {
        self.workoutId = workoutId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exerciseCount = exerciseCount
        self.setCount = setCount
        self.totalVolumeKg = totalVolumeKg
    }

    public var id: UUID { workoutId }

    public var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }
}
