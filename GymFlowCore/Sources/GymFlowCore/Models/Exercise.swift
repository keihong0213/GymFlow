//
//  Exercise.swift
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

public struct Exercise: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var slug: String
    public var category: ExerciseCategory
    public var isCustom: Bool
    public var customName: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        slug: String,
        category: ExerciseCategory,
        isCustom: Bool = false,
        customName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.slug = slug
        self.category = category
        self.isCustom = isCustom
        self.customName = customName
        self.createdAt = createdAt
    }

    public static let databaseTableName = "exercise"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case category
        case isCustom = "is_custom"
        case customName = "custom_name"
        case createdAt = "created_at"
    }
}
