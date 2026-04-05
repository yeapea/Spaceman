//
//  SpacemanStyleTests.swift
//  SpacemanTests
//

import XCTest
@testable import Spaceman

final class SpacemanStyleTests: XCTestCase {
    func testRawValuesAreStable() {
        // These raw values are persisted in UserDefaults under key "displayStyle".
        // Changing them silently would migrate every existing user to a
        // different render style. Guard with explicit expectations.
        XCTAssertEqual(SpacemanStyle.none.rawValue, 0)
        XCTAssertEqual(SpacemanStyle.numbers.rawValue, 1)
        XCTAssertEqual(SpacemanStyle.numbersAndRects.rawValue, 2)
        XCTAssertEqual(SpacemanStyle.desktopNumbersAndRects.rawValue, 3)
        XCTAssertEqual(SpacemanStyle.text.rawValue, 4)
    }

    func testRoundTripsThroughRawValue() {
        for style in [SpacemanStyle.none, .numbers, .numbersAndRects, .desktopNumbersAndRects, .text] {
            XCTAssertEqual(SpacemanStyle(rawValue: style.rawValue), style)
        }
    }

    func testUnknownRawValueProducesNil() {
        XCTAssertNil(SpacemanStyle(rawValue: 99))
        XCTAssertNil(SpacemanStyle(rawValue: -1))
    }
}
