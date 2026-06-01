//
//  HomeViewModel.swift
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
import GymFlowCore

@Observable
final class HomeViewModel {
    var lastSummary: WorkoutSummary?
    var activeDays: Set<Date> = []

    func load(bootstrap: AppBootstrap, now: Date = Date()) {
        do {
            if let last = try bootstrap.workoutRepo.lastWorkout() {
                lastSummary = try bootstrap.workoutRepo.summary(for: last.id)
            } else {
                lastSummary = nil
            }
            let calendar = Calendar.current
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            let recent = try bootstrap.workoutRepo.workouts(since: sevenDaysAgo)
            activeDays = Set(recent.map { calendar.startOfDay(for: $0.startedAt) })
        } catch {
            lastSummary = nil
            activeDays = []
        }
    }

    func last7Days(now: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today)
        }
    }
}
