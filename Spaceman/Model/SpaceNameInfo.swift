//
//  SpaceNameInfo.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 6/12/20.
//

import Foundation

struct SpaceNameInfo: Hashable, Codable {
    let spaceNum: Int
    let spaceName: String

    init(spaceNum: Int, spaceName: String) {
        self.spaceNum = spaceNum
        self.spaceName = String(spaceName.prefix(Constants.Layout.maxSpaceNameLength))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let spaceNum = try container.decode(Int.self, forKey: .spaceNum)
        let spaceName = try container.decode(String.self, forKey: .spaceName)
        // Route through the validating init so names persisted from
        // older builds (or from a tampered plist) can never exceed the
        // configured length at runtime.
        self.init(spaceNum: spaceNum, spaceName: spaceName)
    }
}
