import Foundation
import GRDB

public struct ExerciseRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func all() throws -> [Exercise] {
        try database.reader.read { db in
            try Exercise.order(Column("slug")).fetchAll(db)
        }
    }

    public func byCategory(_ category: ExerciseCategory) throws -> [Exercise] {
        try database.reader.read { db in
            try Exercise
                .filter(Column("category") == category.rawValue)
                .order(Column("slug"))
                .fetchAll(db)
        }
    }

    public func find(id: UUID) throws -> Exercise? {
        try database.reader.read { db in
            try Exercise.fetchOne(db, key: id.uuidString)
        }
    }

    public func find(slug: String) throws -> Exercise? {
        try database.reader.read { db in
            try Exercise.filter(Column("slug") == slug).fetchOne(db)
        }
    }

    @discardableResult
    public func createCustom(name: String, category: ExerciseCategory) throws -> Exercise {
        let slug = "custom_" + UUID().uuidString.lowercased()
        let exercise = Exercise(
            slug: slug,
            category: category,
            isCustom: true,
            customName: name
        )
        try database.dbWriter.write { db in
            try exercise.insert(db)
        }
        return exercise
    }

    public func delete(id: UUID) throws {
        _ = try database.dbWriter.write { db in
            try Exercise.deleteOne(db, key: id.uuidString)
        }
    }
}
