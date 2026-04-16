import Foundation
import GRDB

public struct ExerciseSeed: Codable, Sendable {
    public let slug: String
    public let category: ExerciseCategory
    public let names: [String: String]

    public func localizedName(for locale: String) -> String {
        if let exact = names[locale] { return exact }
        let prefix = locale.split(separator: "-").first.map(String.init) ?? locale
        if let lang = names[prefix] { return lang }
        return names["en"] ?? slug
    }
}

public struct ExerciseSeedBundle: Codable, Sendable {
    public let version: Int
    public let exercises: [ExerciseSeed]
}

public enum ExerciseSeedLoader {
    public static func loadBundled(from bundle: Bundle? = nil) throws -> ExerciseSeedBundle {
        let resolved = bundle ?? .module
        guard let url = resolved.url(forResource: "exercises", withExtension: "json") else {
            throw SeedError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ExerciseSeedBundle.self, from: data)
    }

    @discardableResult
    public static func seed(
        into database: AppDatabase,
        bundle: Bundle? = nil
    ) throws -> SeedResult {
        let payload = try loadBundled(from: bundle)
        return try database.dbWriter.write { db in
            var inserted = 0
            var updated = 0
            for item in payload.exercises {
                if let existing = try Exercise.filter(Column("slug") == item.slug).fetchOne(db) {
                    if existing.category != item.category {
                        var row = existing
                        row.category = item.category
                        try row.update(db)
                        updated += 1
                    }
                } else {
                    let row = Exercise(
                        slug: item.slug,
                        category: item.category,
                        isCustom: false
                    )
                    try row.insert(db)
                    inserted += 1
                }
            }
            return SeedResult(inserted: inserted, updated: updated, version: payload.version)
        }
    }

    public enum SeedError: Error, Sendable {
        case resourceNotFound
    }

    public struct SeedResult: Equatable, Sendable {
        public let inserted: Int
        public let updated: Int
        public let version: Int
    }
}
