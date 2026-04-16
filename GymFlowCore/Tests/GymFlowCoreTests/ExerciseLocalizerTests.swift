import XCTest
@testable import GymFlowCore

final class ExerciseLocalizerTests: XCTestCase {
    func test_displayName_allFiveLanguages() throws {
        let loc = try ExerciseLocalizer()
        XCTAssertEqual(loc.displayName(slug: "bench_press", locale: Locale(identifier: "zh-Hant")), "槓鈴臥推")
        XCTAssertEqual(loc.displayName(slug: "bench_press", locale: Locale(identifier: "zh-Hans")), "杠铃卧推")
        XCTAssertEqual(loc.displayName(slug: "bench_press", locale: Locale(identifier: "en")), "Bench Press")
        XCTAssertEqual(loc.displayName(slug: "bench_press", locale: Locale(identifier: "ja")), "ベンチプレス")
        XCTAssertEqual(loc.displayName(slug: "bench_press", locale: Locale(identifier: "ko")), "벤치 프레스")
    }

    func test_displayName_zhTW_resolvesToZhHant() throws {
        let loc = try ExerciseLocalizer()
        XCTAssertEqual(
            loc.displayName(slug: "bench_press", locale: Locale(identifier: "zh_TW")),
            "槓鈴臥推"
        )
    }

    func test_displayName_unsupportedLocale_fallsBackToEnglish() throws {
        let loc = try ExerciseLocalizer()
        XCTAssertEqual(
            loc.displayName(slug: "bench_press", locale: Locale(identifier: "fr_FR")),
            "Bench Press"
        )
    }

    func test_displayName_customExercise_usesCustomName() throws {
        let loc = try ExerciseLocalizer()
        let custom = Exercise(slug: "custom_abc", category: .machine, isCustom: true, customName: "我的動作")
        XCTAssertEqual(loc.displayName(for: custom, locale: Locale(identifier: "en")), "我的動作")
    }

    func test_displayName_unknownSlug_returnsSlug() throws {
        let loc = try ExerciseLocalizer()
        XCTAssertEqual(
            loc.displayName(slug: "does_not_exist", locale: Locale(identifier: "en")),
            "does_not_exist"
        )
    }
}
