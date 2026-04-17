import Foundation
import GRDB

public struct PRRepository: Sendable {
    public let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func currentPRs(for exerciseId: UUID) throws -> [PRRecord] {
        try database.reader.read { db in
            var best: [PRType: PRRecord] = [:]
            let all = try PRRecord
                .filter(Column("exercise_id") == exerciseId.uuidString)
                .order(Column("value_kg").desc, Column("achieved_at").desc)
                .fetchAll(db)
            for record in all {
                if best[record.type] == nil {
                    best[record.type] = record
                }
            }
            return PRType.allCases.compactMap { best[$0] }
        }
    }

    public func allPRs(for exerciseId: UUID) throws -> [PRRecord] {
        try database.reader.read { db in
            try PRRecord
                .filter(Column("exercise_id") == exerciseId.uuidString)
                .order(Column("achieved_at"))
                .fetchAll(db)
        }
    }
}
