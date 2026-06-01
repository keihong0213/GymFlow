//
//  ExerciseHistoryEntry.swift
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
