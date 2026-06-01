//
//  Analytics.swift
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
final class Analytics {
    private let repository: AnalyticsRepository

    init(repository: AnalyticsRepository) {
        self.repository = repository
    }

    func log(_ eventType: String, payload: [String: String] = [:]) {
        do {
            try repository.log(type: eventType, payload: payload)
            #if DEBUG
            print("[analytics] \(eventType) \(payload)")
            #endif
        } catch {
            #if DEBUG
            print("[analytics] failed to log \(eventType): \(error)")
            #endif
        }
    }
}

enum AnalyticsEventType {
    static let workoutStarted = "workout_started"
    static let workoutEnded = "workout_ended"
    static let setLogged = "set_logged"
    static let prDetected = "pr_detected"
}
