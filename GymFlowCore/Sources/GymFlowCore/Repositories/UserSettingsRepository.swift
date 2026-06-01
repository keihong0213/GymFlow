//
//  UserSettingsRepository.swift
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
import GRDB

public struct UserSettingsRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func load() throws -> UserSettings {
        try database.dbWriter.write { db in
            if let existing = try UserSettings.fetchOne(db, key: UserSettings.singletonId) {
                return existing
            }
            let defaults = UserSettings()
            try defaults.insert(db)
            return defaults
        }
    }

    public func save(_ settings: UserSettings) throws {
        var copy = settings
        copy.id = UserSettings.singletonId
        try database.dbWriter.write { db in
            try copy.save(db)
        }
    }
}
