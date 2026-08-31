//
//  SpaceNameInfoTests.swift
//  SpacemanTests
//

import XCTest
@testable import Spaceman

final class SpaceNameInfoTests: XCTestCase {
    func testPropertyListRoundTrip() throws {
        let original: [String: SpaceNameInfo] = [
            "1": SpaceNameInfo(spaceNum: 1, spaceName: "WEB"),
            "2": SpaceNameInfo(spaceNum: 2, spaceName: "DEV"),
            "3": SpaceNameInfo(spaceNum: 3, spaceName: "N/A")
        ]
        let data = try PropertyListEncoder().encode(original)
        let decoded = try PropertyListDecoder().decode([String: SpaceNameInfo].self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testEqualityIsStructural() {
        let lhs = SpaceNameInfo(spaceNum: 1, spaceName: "WEB")
        let rhs = SpaceNameInfo(spaceNum: 1, spaceName: "WEB")
        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
    }

    func testHashableSemantics() {
        var set = Set<SpaceNameInfo>()
        set.insert(SpaceNameInfo(spaceNum: 1, spaceName: "WEB"))
        set.insert(SpaceNameInfo(spaceNum: 1, spaceName: "WEB"))
        set.insert(SpaceNameInfo(spaceNum: 2, spaceName: "WEB"))
        XCTAssertEqual(set.count, 2)
    }
}
