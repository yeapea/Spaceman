//
//  AppDelegate.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

import SwiftUI
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBar = StatusBar()
    private let spaceObserver = SpaceObserver()
    private let iconCreator = IconCreator()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        spaceObserver.delegate = self
        spaceObserver.updateSpaceInformation()
        NSApp.activate()
        KeyboardShortcuts.onKeyUp(for: .refresh) { [weak self] in
            self?.spaceObserver.updateSpaceInformation()
        }
    }

}

extension AppDelegate: SpaceObserverDelegate {
    func didUpdateSpaces(spaces: [Space]) {
        let icon = iconCreator.getIcon(for: spaces)
        statusBar.updateStatusBar(withIcon: icon)
    }

    func didFailToObserveSpaces() {
        statusBar.updateStatusBar(withIcon: iconCreator.getFallbackIcon())
    }
}

@main
struct SpacemanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
