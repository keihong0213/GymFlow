//
//  GymFlowUITests.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import XCTest

final class GymFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGoldenPath_startsSeededSessionAndReachesSummary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--seed-demo"]
        app.launch()

        // Onboarding may appear on fresh install; dismiss if present.
        let onboardingStart = app.buttons.matching(identifier: "onboarding.start").firstMatch
        if onboardingStart.waitForExistence(timeout: 2) {
            onboardingStart.tap()
        }

        let startButton = app.buttons.matching(identifier: "home.start_workout").firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Home start button should be visible after launch")
        startButton.tap()

        let endButton = app.buttons.matching(identifier: "session.end").firstMatch
        XCTAssertTrue(endButton.waitForExistence(timeout: 5), "Session end button should appear once session opens")
        endButton.tap()

        let confirmEnd = app.buttons.matching(identifier: "session.end_confirm").firstMatch
        XCTAssertTrue(confirmEnd.waitForExistence(timeout: 3), "End-session confirmation should appear")
        confirmEnd.tap()

        let doneButton = app.buttons.matching(identifier: "summary.done").firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Summary should be reachable once session ends")
        doneButton.tap()

        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Home start button should be visible again after dismiss")
    }
}
