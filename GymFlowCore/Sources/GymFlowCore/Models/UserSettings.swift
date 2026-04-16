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
