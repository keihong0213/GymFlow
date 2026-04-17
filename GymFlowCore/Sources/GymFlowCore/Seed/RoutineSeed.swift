import Foundation
import GRDB

public struct RoutineSeedExercise: Codable, Sendable {
    public let slug: String
    public let targetSets: Int?
    public let targetRepsMin: Int?
    public let targetRepsMax: Int?
    public let defaultRestSeconds: Int?
}

public struct RoutineSeed: Codable, Sendable {
    public let slug: String
    public let exercises: [RoutineSeedExercise]
}

public struct RoutineSeedBundle: Codable, Sendable {
    public let version: Int
    public let routines: [RoutineSeed]
}

public enum RoutineSeedLoader {
    public static func loadBundled(from bundle: Bundle? = nil) throws -> RoutineSeedBundle {
        let resolved = bundle ?? .module
        guard let url = resolved.url(forResource: "routines", withExtension: "json") else {
            throw SeedError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RoutineSeedBundle.self, from: data)
    }

    @discardableResult
    public static func seed(into database: AppDatabase, bundle: Bundle? = nil) throws -> SeedResult {
        let payload = try loadBundled(from: bundle)
        return try database.dbWriter.write { db in
            var inserted = 0
            var skipped = 0
            for (idx, item) in payload.routines.enumerated() {
                let existing = try Routine.filter(Column("slug") == item.slug).fetchOne(db)
                if existing != nil {
                    skipped += 1
                    continue
                }
                let routine = Routine(
                    name: item.slug,
                    slug: item.slug,
                    isBuiltIn: true,
                    orderIndex: idx,
                    createdAt: Date()
                )
                try routine.insert(db)

                for (exerciseIdx, seed) in item.exercises.enumerated() {
                    guard let exercise = try Exercise.filter(Column("slug") == seed.slug).fetchOne(db) else {
                        continue
                    }
                    let link = RoutineExercise(
                        routineId: routine.id,
                        exerciseId: exercise.id,
                        orderIndex: exerciseIdx,
                        targetSets: seed.targetSets,
                        targetRepsMin: seed.targetRepsMin,
                        targetRepsMax: seed.targetRepsMax,
                        defaultRestSeconds: seed.defaultRestSeconds
                    )
                    try link.insert(db)
                }
                inserted += 1
            }
            return SeedResult(inserted: inserted, skipped: skipped, version: payload.version)
        }
    }

    public enum SeedError: Error, Sendable {
        case resourceNotFound
    }

    public struct SeedResult: Equatable, Sendable {
        public let inserted: Int
        public let skipped: Int
        public let version: Int
    }
}
