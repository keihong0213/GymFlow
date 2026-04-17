import Foundation

public struct ExerciseHistoryEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let workoutId: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let topSet: SetEntry?
    public let totalVolumeKg: Double
    public let setCount: Int

    public init(
        id: UUID,
        workoutId: UUID,
        startedAt: Date,
        endedAt: Date?,
        topSet: SetEntry?,
        totalVolumeKg: Double,
        setCount: Int
    ) {
        self.id = id
        self.workoutId = workoutId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.topSet = topSet
        self.totalVolumeKg = totalVolumeKg
        self.setCount = setCount
    }
}
