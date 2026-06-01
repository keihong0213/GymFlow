//
//  WorkoutSummary.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

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
