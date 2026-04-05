//
//  IconBuilder.swift
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

import AppKit
import Foundation

final class IconCreator {
    private let defaults = UserDefaults.standard
    private var iconSize = NSSize(width: 18, height: 12)
    private let gapWidth = CGFloat(5)
    private let displayGapWidth = CGFloat(15)

    func getIcon(for spaces: [Space]) -> NSImage {
        iconSize.width = 18
        let spacemanStyle = SpacemanStyle(rawValue: defaults.integer(forKey: "displayStyle"))
        var icons = [NSImage]()

        for space in spaces {
            let iconResourceName: String
            switch (space.isCurrentSpace, space.isFullScreen) {
            case (true, true):
                iconResourceName = spacemanStyle == .text ? "NamedFullActive" : "SpaceManIconFullEn"
            case (true, false):
                iconResourceName = "SpaceManIcon"
            case (false, true):
                iconResourceName = spacemanStyle == .text ? "NamedFullInactive" : "SpaceManIconFullDis"
            default:
                iconResourceName = "SpaceManIconBorder"
            }

            icons.append(NSImage(imageLiteralResourceName: iconResourceName))
        }

        switch spacemanStyle {
        case .numbers:
            icons = createNumberedIcons(spaces)
        case .numbersAndRects:
            icons = createRectWithNumbersIcons(icons, spaces, desktopsOnly: false)
        case .desktopNumbersAndRects:
            icons = createRectWithNumbersIcons(icons, spaces, desktopsOnly: true)
        case .text:
            iconSize.width = 49
            icons = createNamedIcons(icons, spaces)
        default:
            break
        }

        let (iconsWithDisplayProperties, displayCount) = getIconsWithDisplayProps(icons: icons, spaces: spaces)
        return mergeIcons(iconsWithDisplayProperties, displayCount: displayCount)
    }

    private func createNumberedIcons(_ spaces: [Space]) -> [NSImage] {
        var newIcons = [NSImage]()

        for space in spaces {
            let textRect = NSRect(origin: CGPoint.zero, size: iconSize)
            let spaceNumber = String(space.spaceNumber)
            let attributes = getStringAttributes(
                alpha: space.isCurrentSpace ? 1 : 0.4,
                fontSize: 12)
            let image = NSImage(size: iconSize, flipped: false) { _ in
                spaceNumber.drawVerticallyCentered(in: textRect, withAttributes: attributes)
                return true
            }
            image.isTemplate = true

            newIcons.append(image)
        }

        return newIcons
    }

    private func createRectWithNumbersIcons(_ icons: [NSImage], _ spaces: [Space], desktopsOnly: Bool) -> [NSImage] {
        var index = 0
        var newIcons = [NSImage]()

        for space in spaces {
            let textRect = NSRect(origin: CGPoint.zero, size: iconSize)
            let number = desktopsOnly ? space.desktopNumber : space.spaceNumber
            let numberImage = NSImage(size: iconSize, flipped: false) { _ in
                if let number {
                    let spaceNumber = String(number)
                    spaceNumber.drawVerticallyCentered(
                        in: textRect,
                        withAttributes: self.getStringAttributes(alpha: 1))
                }
                return true
            }

            let baseIcon = icons[index]
            let iconImage = NSImage(size: iconSize, flipped: false) { _ in
                baseIcon.draw(
                    in: textRect,
                    from: NSRect.zero,
                    operation: NSCompositingOperation.sourceOver,
                    fraction: 1.0)
                numberImage.draw(
                    in: textRect,
                    from: NSRect.zero,
                    operation: NSCompositingOperation.destinationOut,
                    fraction: 1.0)
                return true
            }
            iconImage.isTemplate = true

            newIcons.append(iconImage)
            index += 1
        }

        return newIcons
    }

    private func createNamedIcons(_ icons: [NSImage], _ spaces: [Space]) -> [NSImage] {
        var index = 0
        var newIcons = [NSImage]()

        for space in spaces {
            let textRect = NSRect(origin: CGPoint.zero, size: iconSize)
            let spaceText = "\(space.spaceNumber): \(space.spaceName.uppercased())"
            let textImage = NSImage(size: iconSize, flipped: false) { _ in
                spaceText.drawVerticallyCentered(
                    in: textRect,
                    withAttributes: self.getStringAttributes(alpha: 1))
                return true
            }

            let baseIcon = icons[index]
            let iconImage = NSImage(size: iconSize, flipped: false) { _ in
                baseIcon.draw(
                    in: textRect,
                    from: NSRect.zero,
                    operation: NSCompositingOperation.sourceOver,
                    fraction: 1.0)
                textImage.draw(
                    in: textRect,
                    from: NSRect.zero,
                    operation: NSCompositingOperation.destinationOut,
                    fraction: 1.0)
                return true
            }
            iconImage.isTemplate = true

            newIcons.append(iconImage)
            index += 1
        }

        return newIcons
    }

    func getIconsWithDisplayProps(icons: [NSImage], spaces: [Space]) -> (icons: [(NSImage, Bool)], displayCount: Int) {
        var iconsWithDisplayProperties = [(NSImage, Bool)]()
        var currentDisplayID = spaces[0].displayID
        var displayCount = 1

        for index in 0 ..< spaces.count {
            var nextSpaceIsOnDifferentDisplay = false

            if index + 1 < spaces.count {
                let thisDispID = spaces[index + 1].displayID
                if thisDispID != currentDisplayID {
                    currentDisplayID = thisDispID
                    displayCount += 1
                    nextSpaceIsOnDifferentDisplay = true
                }
            }

            iconsWithDisplayProperties.append((icons[index], nextSpaceIsOnDifferentDisplay))
        }

        return (iconsWithDisplayProperties, displayCount)
    }

    func mergeIcons(
        _ iconsWithDisplayProperties: [(image: NSImage, nextSpaceOnDifferentDisplay: Bool)],
        displayCount: Int
    ) -> NSImage {
        let numIcons = iconsWithDisplayProperties.count
        let combinedIconWidth = CGFloat(numIcons) * iconSize.width
        let accomodatingGapWidth = CGFloat(numIcons - 1) * gapWidth
        let accomodatingDisplayGapWidth = CGFloat(displayCount - 1) * displayGapWidth
        let totalWidth = combinedIconWidth + accomodatingGapWidth + accomodatingDisplayGapWidth
        let iconHeight = iconSize.height
        let iconWidth = iconSize.width
        let gapWidth = self.gapWidth
        let displayGapWidth = self.displayGapWidth
        let image = NSImage(
            size: NSSize(width: totalWidth, height: iconHeight),
            flipped: false
        ) { _ in
            var xOffset = CGFloat.zero
            for icon in iconsWithDisplayProperties {
                icon.image.draw(
                    at: NSPoint(x: xOffset, y: 0),
                    from: NSRect.zero,
                    operation: NSCompositingOperation.sourceOver,
                    fraction: 1.0)
                if icon.nextSpaceOnDifferentDisplay {
                    xOffset += iconWidth + displayGapWidth
                } else {
                    xOffset += iconWidth + gapWidth
                }
            }
            return true
        }
        image.isTemplate = true

        return image
    }

    private func getStringAttributes(alpha: CGFloat, fontSize: CGFloat = 10) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return [
            .foregroundColor: NSColor.black.withAlphaComponent(alpha),
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
            .paragraphStyle: paragraphStyle]
    }
}
