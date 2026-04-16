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
