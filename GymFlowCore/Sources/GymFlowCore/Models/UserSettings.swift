//
//  UserSettings.swift
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

public struct UserSettings: Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public static let singletonId = 1

    public var id: Int
    public var units: WeightUnit
    public var language: AppLanguage
    public var defaultRestSeconds: Int
    public var appearance: Appearance

    public init(
        id: Int = UserSettings.singletonId,
        units: WeightUnit = .kg,
        language: AppLanguage = .system,
        defaultRestSeconds: Int = 90,
        appearance: Appearance = .system
    ) {
        self.id = id
        self.units = units
        self.language = language
        self.defaultRestSeconds = defaultRestSeconds
        self.appearance = appearance
    }

    public static let databaseTableName = "user_settings"

    enum CodingKeys: String, CodingKey {
        case id
        case units
        case language
        case defaultRestSeconds = "default_rest_seconds"
        case appearance
    }
}
