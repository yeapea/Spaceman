//
//  NotificationName+Spaceman.swift
//  Spaceman
//
//  Typed notification names used across the app. Replaces the legacy
//  stringly-typed "ButtonPressed" name that previously coupled the
//  SpaceObserver, PreferencesView, and PreferencesViewModel.
//

import Foundation

extension Notification.Name {
    /// Request a refresh of the rendered status-bar icon. Posted by the
    /// preferences UI (style picker, name edit, periodic timer) and
    /// consumed by `SpaceObserver`.
    static let spacemanRefresh = Notification.Name("dev.jaysce.Spaceman.refresh")
}
