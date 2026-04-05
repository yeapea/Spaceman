//
//  Constants.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 7/11/21.
//

import CoreGraphics
import Foundation

enum Constants {
    /// Layout metrics for the composited status-bar icon. Changing
    /// these values changes the visual width of the menu-bar item.
    enum Layout {
        /// Size of a single space icon in points.
        static let iconSize = CGSize(width: 18, height: 12)
        /// Width of a single space icon when rendering the "Named spaces"
        /// style, which needs room for three characters of text.
        static let textIconWidth: CGFloat = 49
        /// Horizontal gap between spaces on the same display.
        static let gapWidth: CGFloat = 5
        /// Horizontal gap between groups of spaces that belong to
        /// different displays.
        static let displayGapWidth: CGFloat = 15
        /// Maximum length of a user-supplied space name.
        static let maxSpaceNameLength = 3
    }

    enum AppInfo {
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        static let repo: URL = {
            guard let url = URL(string: "https://github.com/Jaysce/Spaceman") else {
                fatalError("Invalid repository URL")
            }
            return url
        }()
        static let website: URL = {
            guard let url = URL(string: "https://jaysce.dev/projects/spaceman") else {
                fatalError("Invalid website URL")
            }
            return url
        }()
    }
}
