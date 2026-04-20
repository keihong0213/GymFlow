import Foundation

public struct BackupBundle: Codable, Sendable {
    public let schemaVersion: Int
    public let exportedAt: Date
    public let exercises: [ExerciseExport]
    public let workouts: [WorkoutExport]
}

public struct ExerciseExport: Codable, Sendable {
    public let id: UUID
    public let slug: String
    public let category: String
    public let isCustom: Bool
    public let customName: String?
}

public struct WorkoutExport: Codable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let exercises: [WorkoutExerciseExport]
}

public struct WorkoutExerciseExport: Codable, Sendable {
    public let exerciseSlug: String
    public let orderIndex: Int
    public let sets: [SetExport]
}

public struct SetExport: Codable, Sendable {
    public let setNumber: Int
    public let weightKg: Double
    public let reps: Int
    public let isWarmup: Bool
    public let durationSec: Int?
    public let distanceMeters: Double?
    public let completedAt: Date
}

public struct BackupService: Sendable {
    public let workoutRepo: WorkoutRepository
    public let exerciseRepo: ExerciseRepository

    public init(workoutRepo: WorkoutRepository, exerciseRepo: ExerciseRepository) {
        self.workoutRepo = workoutRepo
        self.exerciseRepo = exerciseRepo
    }

    public func buildBundle() throws -> BackupBundle {
        let allExercises = try exerciseRepo.all()
        let exportedExercises = allExercises.map { ex in
            ExerciseExport(
                id: ex.id,
                slug: ex.slug,
                category: ex.category.rawValue,
                isCustom: ex.isCustom,
                customName: ex.customName
            )
        }
        let exerciseById = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })

        let completed = try workoutRepo.completedWorkouts()
        var workoutExports: [WorkoutExport] = []
        for workout in completed {
            let rows = try workoutRepo.exercises(for: workout.id)
            var blocks: [WorkoutExerciseExport] = []
            for row in rows {
                guard let exercise = exerciseById[row.exerciseId] else { continue }
                let sets = try workoutRepo.sets(for: row.id)
                let exportedSets = sets.map { set in
                    SetExport(
                        setNumber: set.setNumber,
                        weightKg: set.weightKg,
                        reps: set.reps,
                        isWarmup: set.isWarmup,
                        durationSec: set.durationSec,
                        distanceMeters: set.distanceMeters,
                        completedAt: set.completedAt
                    )
                }
                blocks.append(WorkoutExerciseExport(
                    exerciseSlug: exercise.slug,
                    orderIndex: row.orderIndex,
                    sets: exportedSets
                ))
            }
            workoutExports.append(WorkoutExport(
                id: workout.id,
                startedAt: workout.startedAt,
                endedAt: workout.endedAt,
                exercises: blocks
            ))
        }

        return BackupBundle(
            schemaVersion: 3,
            exportedAt: Date(),
            exercises: exportedExercises,
            workouts: workoutExports
        )
    }

    public func buildJSON() throws -> Data {
        let bundle = try buildBundle()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bundle)
    }

    public func buildCSV() throws -> String {
        let bundle = try buildBundle()
        let iso = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append("workout_started_at,workout_ended_at,exercise_slug,order,set_number,weight_kg,reps,duration_sec,distance_m,is_warmup,completed_at")
        for workout in bundle.workouts {
            let started = iso.string(from: workout.startedAt)
            let ended = workout.endedAt.map(iso.string(from:)) ?? ""
            for block in workout.exercises {
                for set in block.sets {
                    let duration = set.durationSec.map(String.init) ?? ""
                    let distance = set.distanceMeters.map { String($0) } ?? ""
                    let completed = iso.string(from: set.completedAt)
                    let fields = [
                        started,
                        ended,
                        block.exerciseSlug,
                        "\(block.orderIndex)",
                        "\(set.setNumber)",
                        String(set.weightKg),
                        "\(set.reps)",
                        duration,
                        distance,
                        set.isWarmup ? "1" : "0",
                        completed,
                    ]
                    lines.append(fields.map(Self.csvEscape).joined(separator: ","))
                }
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public func writeJSONToTempFile() throws -> URL {
        let data = try buildJSON()
        return try Self.writeToTempFile(data: data, preferredFilename: "gymflow-backup.json")
    }

    public func writeCSVToTempFile() throws -> URL {
        let csv = try buildCSV()
        guard let data = csv.data(using: .utf8) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        return try Self.writeToTempFile(data: data, preferredFilename: "gymflow-workouts.csv")
    }

    private static func writeToTempFile(data: Data, preferredFilename: String) throws -> URL {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = df.string(from: Date())
        let base = (preferredFilename as NSString).deletingPathExtension
        let ext = (preferredFilename as NSString).pathExtension
        let filename = "\(base)-\(stamp).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return s
    }
}
