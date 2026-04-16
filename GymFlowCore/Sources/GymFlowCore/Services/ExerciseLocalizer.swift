import Foundation

public final class ExerciseLocalizer: Sendable {
    private let table: [String: ExerciseSeed]

    public init(bundle: Bundle? = nil) throws {
        let payload = try ExerciseSeedLoader.loadBundled(from: bundle)
        var map: [String: ExerciseSeed] = [:]
        for seed in payload.exercises {
            map[seed.slug] = seed
        }
        self.table = map
    }

    public init(seeds: [ExerciseSeed]) {
        var map: [String: ExerciseSeed] = [:]
        for seed in seeds {
            map[seed.slug] = seed
        }
        self.table = map
    }

    public func displayName(for exercise: Exercise, locale: Locale = .current) -> String {
        if exercise.isCustom, let custom = exercise.customName, !custom.isEmpty {
            return custom
        }
        return displayName(slug: exercise.slug, locale: locale)
    }

    public func displayName(slug: String, locale: Locale = .current) -> String {
        guard let seed = table[slug] else { return slug }
        return seed.localizedName(for: Self.resolve(locale: locale))
    }

    static func resolve(locale: Locale) -> String {
        let id = locale.identifier
        if id.hasPrefix("zh") {
            let script = locale.language.script?.identifier
            if script == "Hant" { return "zh-Hant" }
            if script == "Hans" { return "zh-Hans" }
            let region = locale.region?.identifier
            if let region, ["TW", "HK", "MO"].contains(region) { return "zh-Hant" }
            return "zh-Hans"
        }
        if id.hasPrefix("ja") { return "ja" }
        if id.hasPrefix("ko") { return "ko" }
        return "en"
    }
}
