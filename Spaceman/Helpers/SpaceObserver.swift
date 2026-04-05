//
//  SpaceObserver.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

import Cocoa
import Foundation

final class SpaceObserver {
    private let workspace = NSWorkspace.shared
    private let conn = _CGSDefaultConnection()
    private let defaults = UserDefaults.standard
    weak var delegate: SpaceObserverDelegate?

    init() {
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(updateSpaceInformation),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: workspace)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSpaceInformation),
            name: .spacemanRefresh,
            object: nil)
    }

    deinit {
        workspace.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc public func updateSpaceInformation() {
        guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [[String: Any]] else {
            Log.spaceObserver.error("CGSCopyManagedDisplaySpaces returned unexpected shape")
            delegate?.didFailToObserveSpaces()
            return
        }

        let savedSpaceNames = loadSavedSpaceNames()
        var spacesIndex = 0
        var allSpaces = [Space]()
        var updatedDict = [String: SpaceNameInfo]()

        for display in displays {
            guard let parsedDisplay = SpaceParser.parseDisplay(display) else {
                Log.spaceObserver.warning("Skipping display with unexpected payload")
                continue
            }

            if parsedDisplay.activeSpaceID == -1 {
                Log.spaceObserver.error("Cannot find current space for display \(parsedDisplay.displayID, privacy: .public)")
                delegate?.didFailToObserveSpaces()
                return
            }

            let built = SpaceParser.buildSpaces(
                for: parsedDisplay,
                savedSpaceNames: savedSpaceNames,
                startIndex: spacesIndex)
            allSpaces.append(contentsOf: built.spaces)
            updatedDict.merge(built.updatedNames) { _, new in new }
            spacesIndex = built.nextIndex
        }

        defaults.set(try? PropertyListEncoder().encode(updatedDict), forKey: "spaceNames")
        delegate?.didUpdateSpaces(spaces: allSpaces)
    }

    private func loadSavedSpaceNames() -> [String: SpaceNameInfo] {
        guard let data = defaults.value(forKey: "spaceNames") as? Data else {
            return [:]
        }

        return (try? PropertyListDecoder().decode([String: SpaceNameInfo].self, from: data)) ?? [:]
    }
}

protocol SpaceObserverDelegate: AnyObject {
    func didUpdateSpaces(spaces: [Space])
    /// Called when the CGS SPI returns data that cannot be interpreted.
    /// Implementations should present a user-visible fallback so the
    /// breakage is diagnosable rather than silent.
    func didFailToObserveSpaces()
}
