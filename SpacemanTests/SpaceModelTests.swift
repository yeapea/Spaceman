//
//  SpaceModelTests.swift
//  SpacemanTests
//

import XCTest
@testable import Spaceman

final class SpaceModelTests: XCTestCase {
    func testMemberwiseInit() {
        let space = Space(
            displayID: "display-1",
            spaceID: "42",
            spaceName: "WEB",
            spaceNumber: 1,
            desktopNumber: 1,
            isCurrentSpace: true,
            isFullScreen: false
        )
        XCTAssertEqual(space.displayID, "display-1")
        XCTAssertEqual(space.spaceID, "42")
        XCTAssertEqual(space.spaceName, "WEB")
        XCTAssertEqual(space.spaceNumber, 1)
        XCTAssertEqual(space.desktopNumber, 1)
        XCTAssertTrue(space.isCurrentSpace)
        XCTAssertFalse(space.isFullScreen)
    }

    func testFullScreenSpaceHasNoDesktopNumber() {
        let space = Space(
            displayID: "display-1",
            spaceID: "43",
            spaceName: "SAF",
            spaceNumber: 2,
            desktopNumber: nil,
            isCurrentSpace: false,
            isFullScreen: true
        )
        XCTAssertNil(space.desktopNumber)
        XCTAssertTrue(space.isFullScreen)
    }
}
