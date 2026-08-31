//
//  SpaceParserTests.swift
//  SpacemanTests
//
//  Fixture-based tests for SpaceParser. These exercise the pure
//  parsing logic with the same dictionary shape that
//  CGSCopyManagedDisplaySpaces returns, so no private SPI is
//  required at test time.
//

import XCTest
@testable import Spaceman

final class SpaceParserTests: XCTestCase {
    // MARK: - parseDisplay

    func testParseDisplayReturnsNilOnMissingKeys() {
        XCTAssertNil(SpaceParser.parseDisplay([:]))
        XCTAssertNil(SpaceParser.parseDisplay([
            "Current Space": ["ManagedSpaceID": 1],
            "Spaces": [[String: Any]]()
            // missing Display Identifier
        ]))
        XCTAssertNil(SpaceParser.parseDisplay([
            "Current Space": [String: Any](),
            "Spaces": [[String: Any]](),
            "Display Identifier": "A"
            // Current Space without ManagedSpaceID
        ]))
    }

    func testParseDisplayExtractsFields() {
        let display: [String: Any] = [
            "Current Space": ["ManagedSpaceID": 7],
            "Spaces": [["ManagedSpaceID": 7], ["ManagedSpaceID": 8]],
            "Display Identifier": "Main"
        ]
        let parsed = SpaceParser.parseDisplay(display)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.activeSpaceID, 7)
        XCTAssertEqual(parsed?.displayID, "Main")
        XCTAssertEqual(parsed?.spaces.count, 2)
    }

    // MARK: - buildSpaces

    func testBuildSpacesNumbersDesktopsAndFlagsCurrent() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 11,
            spaces: [
                ["ManagedSpaceID": 10],
                ["ManagedSpaceID": 11],
                ["ManagedSpaceID": 12]
            ],
            displayID: "D1"
        )

        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: [:],
            startIndex: 0
        )

        XCTAssertEqual(result.nextIndex, 3)
        XCTAssertEqual(result.spaces.count, 3)

        XCTAssertEqual(result.spaces[0].spaceID, "10")
        XCTAssertEqual(result.spaces[0].spaceNumber, 1)
        XCTAssertEqual(result.spaces[0].desktopNumber, 1)
        XCTAssertFalse(result.spaces[0].isCurrentSpace)
        XCTAssertFalse(result.spaces[0].isFullScreen)

        XCTAssertEqual(result.spaces[1].spaceID, "11")
        XCTAssertEqual(result.spaces[1].desktopNumber, 2)
        XCTAssertTrue(result.spaces[1].isCurrentSpace)

        XCTAssertEqual(result.spaces[2].spaceID, "12")
        XCTAssertEqual(result.spaces[2].spaceNumber, 3)
        XCTAssertEqual(result.spaces[2].desktopNumber, 3)
    }

    func testBuildSpacesSkipsDesktopNumberForFullScreen() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 0,
            spaces: [
                ["ManagedSpaceID": 20],
                ["ManagedSpaceID": 21, "TileLayoutManager": [String: Any]()],
                ["ManagedSpaceID": 22]
            ],
            displayID: "D1"
        )

        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: [:],
            startIndex: 0
        )

        XCTAssertEqual(result.spaces[0].desktopNumber, 1)
        XCTAssertNil(result.spaces[1].desktopNumber)
        XCTAssertTrue(result.spaces[1].isFullScreen)
        XCTAssertEqual(result.spaces[2].desktopNumber, 2,
                       "full-screen space should not consume a desktop number")
    }

    func testBuildSpacesHonoursStartIndex() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 0,
            spaces: [["ManagedSpaceID": 30], ["ManagedSpaceID": 31]],
            displayID: "D2"
        )
        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: [:],
            startIndex: 5
        )
        XCTAssertEqual(result.spaces[0].spaceNumber, 6)
        XCTAssertEqual(result.spaces[1].spaceNumber, 7)
        XCTAssertEqual(result.nextIndex, 7)
    }

    func testBuildSpacesUsesSavedNameWhenAvailable() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 0,
            spaces: [["ManagedSpaceID": 40]],
            displayID: "D1"
        )
        let saved = ["40": SpaceNameInfo(spaceNum: 1, spaceName: "WEB")]
        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: saved,
            startIndex: 0
        )
        XCTAssertEqual(result.spaces[0].spaceName, "WEB")
        XCTAssertEqual(result.updatedNames["40"]?.spaceName, "WEB")
        XCTAssertEqual(result.updatedNames["40"]?.spaceNum, 1)
    }

    func testBuildSpacesDefaultsNonFullScreenNameToNA() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 0,
            spaces: [["ManagedSpaceID": 50]],
            displayID: "D1"
        )
        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: [:],
            startIndex: 0
        )
        XCTAssertEqual(result.spaces[0].spaceName, "N/A")
    }

    func testBuildSpacesDefaultsFullScreenNameToFULWithoutPID() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 0,
            spaces: [[
                "ManagedSpaceID": 60,
                "TileLayoutManager": [String: Any]()
            ]],
            displayID: "D1"
        )
        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: [:],
            startIndex: 0
        )
        XCTAssertEqual(result.spaces[0].spaceName, "FUL")
        XCTAssertTrue(result.spaces[0].isFullScreen)
    }

    func testBuildSpacesSkipsEntriesWithoutManagedSpaceID() {
        let display = SpaceParser.DisplayInfo(
            activeSpaceID: 0,
            spaces: [
                ["ManagedSpaceID": 70],
                ["WrongKey": 71],
                ["ManagedSpaceID": 72]
            ],
            displayID: "D1"
        )
        let result = SpaceParser.buildSpaces(
            for: display,
            savedSpaceNames: [:],
            startIndex: 0
        )
        XCTAssertEqual(result.spaces.count, 2)
        XCTAssertEqual(result.spaces[0].spaceID, "70")
        XCTAssertEqual(result.spaces[1].spaceID, "72")
        XCTAssertEqual(result.nextIndex, 2)
    }
}
