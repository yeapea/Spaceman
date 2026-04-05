//
//  Log.swift
//  Spaceman
//
//  Central os.Logger instances for the app. Prefer these over print(...)
//  so messages are attributable to our subsystem and respect unified
//  logging privacy / filtering.
//

import OSLog

enum Log {
    static let subsystem = "dev.jaysce.Spaceman"

    static let spaceObserver = Logger(subsystem: subsystem, category: "SpaceObserver")
    static let preferences = Logger(subsystem: subsystem, category: "Preferences")
    static let iconCreator = Logger(subsystem: subsystem, category: "IconCreator")
}
