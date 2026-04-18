import Foundation
import GRDB

public final class AppDatabase: Sendable {
    public let dbWriter: any DatabaseWriter

    public init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    public static func onDisk(path: URL) throws -> AppDatabase {
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(path: path.path, configuration: config)
        return try AppDatabase(queue)
    }

    public static func inMemory() throws -> AppDatabase {
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(configuration: config)
        return try AppDatabase(queue)
    }

    public var reader: any DatabaseReader { dbWriter }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "exercise") { t in
                t.primaryKey("id", .text).notNull()
                t.column("slug", .text).notNull().indexed()
                t.column("category", .text).notNull()
                t.column("is_custom", .boolean).notNull().defaults(to: false)
                t.column("custom_name", .text)
                t.column("created_at", .datetime).notNull()
                t.uniqueKey(["slug"])
            }

            try db.create(table: "routine") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("slug", .text)
                t.column("is_built_in", .boolean).notNull().defaults(to: false)
                t.column("order_index", .integer).notNull().defaults(to: 0)
                t.column("created_at", .datetime).notNull()
            }

            try db.create(table: "routine_exercise") { t in
                t.primaryKey("id", .text).notNull()
                t.column("routine_id", .text)
                    .notNull()
                    .references("routine", onDelete: .cascade)
                t.column("exercise_id", .text)
                    .notNull()
                    .references("exercise", onDelete: .restrict)
                t.column("order_index", .integer).notNull()
                t.column("target_sets", .integer)
                t.column("target_reps_min", .integer)
                t.column("target_reps_max", .integer)
                t.column("default_rest_seconds", .integer)
            }
            try db.create(
                index: "idx_routine_exercise_routine_order",
                on: "routine_exercise",
                columns: ["routine_id", "order_index"]
            )

            try db.create(table: "workout") { t in
                t.primaryKey("id", .text).notNull()
                t.column("started_at", .datetime).notNull().indexed()
                t.column("ended_at", .datetime)
                t.column("routine_id", .text).references("routine", onDelete: .setNull)
                t.column("notes", .text)
            }

            try db.create(table: "workout_exercise") { t in
                t.primaryKey("id", .text).notNull()
                t.column("workout_id", .text)
                    .notNull()
                    .references("workout", onDelete: .cascade)
                t.column("exercise_id", .text)
                    .notNull()
                    .references("exercise", onDelete: .restrict)
                t.column("order_index", .integer).notNull()
                t.column("notes", .text)
            }
            try db.create(
                index: "idx_workout_exercise_workout_order",
                on: "workout_exercise",
                columns: ["workout_id", "order_index"]
            )

            try db.create(table: "set_entry") { t in
                t.primaryKey("id", .text).notNull()
                t.column("workout_exercise_id", .text)
                    .notNull()
                    .references("workout_exercise", onDelete: .cascade)
                t.column("set_number", .integer).notNull()
                t.column("weight_kg", .double).notNull()
                t.column("reps", .integer).notNull()
                t.column("is_warmup", .boolean).notNull().defaults(to: false)
                t.column("rpe", .double)
                t.column("completed_at", .datetime).notNull()
            }
            try db.create(
                index: "idx_set_entry_we_set",
                on: "set_entry",
                columns: ["workout_exercise_id", "set_number"]
            )

            try db.create(table: "pr_record") { t in
                t.primaryKey("id", .text).notNull()
                t.column("exercise_id", .text)
                    .notNull()
                    .references("exercise", onDelete: .cascade)
                t.column("type", .text).notNull()
                t.column("value_kg", .double).notNull()
                t.column("weight_kg", .double).notNull()
                t.column("reps", .integer).notNull()
                t.column("achieved_at", .datetime).notNull()
                t.column("workout_exercise_id", .text)
                    .notNull()
                    .references("workout_exercise", onDelete: .cascade)
            }
            try db.create(
                index: "idx_pr_record_exercise_type",
                on: "pr_record",
                columns: ["exercise_id", "type"]
            )

            try db.create(table: "user_settings") { t in
                t.primaryKey("id", .integer).notNull()
                t.column("units", .text).notNull()
                t.column("language", .text).notNull()
                t.column("default_rest_seconds", .integer).notNull()
                t.column("appearance", .text).notNull()
            }
        }

        migrator.registerMigration("v2_analytics_event") { db in
            try db.create(table: "analytics_event") { t in
                t.primaryKey("id", .text).notNull()
                t.column("occurred_at", .datetime).notNull()
                t.column("event_type", .text).notNull()
                t.column("payload_json", .text)
                t.column("synced_at", .datetime)
            }
            try db.create(
                index: "idx_analytics_occurred",
                on: "analytics_event",
                columns: ["occurred_at"]
            )
        }

        return migrator
    }
}
