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
