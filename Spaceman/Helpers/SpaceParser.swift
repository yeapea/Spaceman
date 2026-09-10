//
//  SpaceParser.swift
//  Spaceman
//
//  Pure parsing of the dictionaries returned by CGSCopyManagedDisplaySpaces
//  into Spaceman's Space model. Extracted from SpaceObserver so the
//  transformation can be unit tested with fixture payloads without
//  needing to invoke the private CoreGraphics SPI.
//

import Foundation

#if canImport(AppKit)
import AppKit
#endif

enum SpaceParser {
    struct DisplayInfo: Equatable {
        let activeSpaceID: Int
        let spaces: [[String: Any]]
        let displayID: String

        static func == (lhs: DisplayInfo, rhs: DisplayInfo) -> Bool {
            lhs.activeSpaceID == rhs.activeSpaceID && lhs.displayID == rhs.displayID
        }
    }

    struct ParseResult {
        let spaces: [Space]
        let updatedNames: [String: SpaceNameInfo]
        let nextIndex: Int
    }

    /// Parses a single display dictionary returned by
    /// `CGSCopyManagedDisplaySpaces`. Returns nil if required keys are
    /// missing or have unexpected types.
    static func parseDisplay(_ display: [String: Any]) -> DisplayInfo? {
        guard let currentSpaceInfo = display["Current Space"] as? [String: Any],
              let spaces = display["Spaces"] as? [[String: Any]],
              let displayID = display["Display Identifier"] as? String,
              let activeSpaceID = currentSpaceInfo["ManagedSpaceID"] as? Int
        else {
            return nil
        }

        return DisplayInfo(activeSpaceID: activeSpaceID, spaces: spaces, displayID: displayID)
    }

    /// Builds `Space` values for the given parsed display. `startIndex` is
    /// the zero-based offset into the overall space list across all
    /// displays; it becomes `spaceNumber = startIndex + 1` for the first
    /// space of this display.
    static func buildSpaces(
        for display: DisplayInfo,
        savedSpaceNames: [String: SpaceNameInfo],
        startIndex: Int
    ) -> ParseResult {
        var spacesIndex = startIndex
        var lastDesktopNumber = 0
        var spaces: [Space] = []
        var updatedNames: [String: SpaceNameInfo] = [:]

        for spaceInfo in display.spaces {
            guard let managedSpaceID = spaceInfo["ManagedSpaceID"] as? Int else {
                continue
            }

            let spaceID = String(managedSpaceID)
            let spaceNumber = spacesIndex + 1
            let isCurrentSpace = display.activeSpaceID == managedSpaceID
            let isFullScreen = spaceInfo["TileLayoutManager"] is [String: Any]
            let desktopNumber: Int?

            if isFullScreen {
                desktopNumber = nil
            } else {
                lastDesktopNumber += 1
                desktopNumber = lastDesktopNumber
            }

            let space = Space(
                displayID: display.displayID,
                spaceID: spaceID,
                spaceName: savedSpaceNames[spaceID]?.spaceName
                    ?? defaultSpaceName(for: spaceInfo, isFullScreen: isFullScreen),
                spaceNumber: spaceNumber,
                desktopNumber: desktopNumber,
                isCurrentSpace: isCurrentSpace,
                isFullScreen: isFullScreen)

            updatedNames[spaceID] = SpaceNameInfo(spaceNum: spaceNumber, spaceName: space.spaceName)
            spaces.append(space)
            spacesIndex += 1
        }

        return ParseResult(spaces: spaces, updatedNames: updatedNames, nextIndex: spacesIndex)
    }

    private static func defaultSpaceName(for spaceInfo: [String: Any], isFullScreen: Bool) -> String {
        guard isFullScreen else {
            return "N/A"
        }

        #if canImport(AppKit)
        if let pid = spaceInfo["pid"] as? pid_t,
           let app = NSRunningApplication(processIdentifier: pid),
           let name = app.localizedName {
            return String(name.prefix(3)).uppercased()
        }
        #endif

        return "FUL"
    }
}
