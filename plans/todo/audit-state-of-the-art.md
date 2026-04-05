# Audit — State of the Art

Scope: compare Spaceman's codebase against current Apple platform best
practices as of macOS 15 Sequoia / Xcode 16. The app is already modern in
many ways (SwiftUI lifecycle, SwiftPM, Sparkle 2 EdDSA). This document
lists what could be modernized further.

---

## 1. Swift language / toolchain

- `SWIFT_VERSION = 5.0` in the Xcode project. Bump to Swift 5.10 (or 6)
  and enable strict concurrency checking incrementally:
  - `SWIFT_STRICT_CONCURRENCY = minimal → targeted → complete`.
  - Expect warnings in `SpaceObserver`, `PreferencesViewModel`,
    `StatusBar`, which touch `@MainActor`-bound AppKit types from mixed
    contexts.
- Adopt the `Observation` framework (`@Observable`) for
  `PreferencesViewModel` instead of `ObservableObject` + `@Published`.
  Available since macOS 14 → safe on our 15 baseline.
- Replace `@StateObject` with `@State` (paired with `@Observable`) where
  applicable.

## 2. Concurrency model

**Files:** `SpaceObserver.swift`, `PreferencesViewModel.swift`,
`AppDelegate.swift`

- `SpaceObserver` is invoked from NSWorkspace notifications and a manual
  `Timer` (in the view model). Migrate to:
  - `Timer.publish` / `AsyncSequence` for the periodic refresh, or
  - a `Task { for await _ in workspace.notificationCenter.notifications(
    named: .activeSpaceDidChange) { ... } }` pattern with structured
    cancellation tied to app lifecycle.
- `DispatchQueue.main.async { print(...) }` is a code smell. Hop to main
  with `await MainActor.run { ... }` or annotate the method
  `@MainActor`.
- The `delegate` pattern between `SpaceObserver` and `AppDelegate` can
  stay, but should be annotated `@MainActor` because it eventually drives
  AppKit.

## 3. SwiftUI lifecycle / navigation

- Preferences uses a custom `NSWindow` host. macOS 14+ provides the
  `Settings { ... }` scene plus `SettingsLink` (macOS 14) / `.settings`
  menu command. The current "Settings { EmptyView() }" in `SpacemanApp`
  is a placeholder — consider moving the preferences UI fully into the
  `Settings` scene and removing `PreferencesWindow.swift`.
- Use `MenuBarExtra` (macOS 13+) instead of an ad-hoc `NSStatusItem`
  wrapped in `StatusBar.swift`. This would remove a large amount of
  AppKit glue. Trade-off: custom rendered `NSImage` status bar button
  might still need `.menuBarExtraStyle(.window)` or the `NSStatusItem`
  path. Evaluate feasibility — if the rendered image is dynamic, the
  current approach may still be needed.
- Replace `NSHostingView` call sites with `NSHostingController` where
  possible; SwiftUI 5 has fewer sizing quirks with controllers.

## 4. Data persistence

- `UserDefaults.standard` + `PropertyListEncoder` is fine for this tiny
  dataset. Modernize with `@AppStorage` plus a `Codable` wrapper extension
  (or `RawRepresentable` conformance) so the view model doesn't manually
  encode/decode.
- `SpacemanStyle` is stored as raw `Int`. `@AppStorage` supports
  `RawRepresentable` directly — use it and drop the manual
  `SpacemanStyle(rawValue: defaults.integer(forKey:))` lookup.

## 5. Drawing pipeline

**File:** `IconCreator.swift`

- `lockFocus` / `unlockFocus` is legacy AppKit. Current best practice:
  `NSImage(size:, flipped:, drawingHandler:)` or draw into a
  `CGContext` explicitly via `NSGraphicsContext`.
- Consider rendering via SwiftUI (`ImageRenderer` on macOS 13+) for the
  styled variants. You'd get dark-mode-aware colors, Dynamic Type, and
  easier previewing.
- Status bar images should be template images rendered at `@2x` for
  Retina displays; verify by inspecting the produced `NSImage.size` vs
  actual bitmap representation size.

## 6. Observation / state flow

- Replace the `"ButtonPressed"` stringly-typed notification with:
  - A Combine `PassthroughSubject<Void, Never>` or an `AsyncStream`, or
  - A dedicated `@Observable` coordinator that both the view model and
    `SpaceObserver` share.
- This removes cross-module NotificationCenter coupling and makes data
  flow traceable.

## 7. Testing

- No XCTest target exists. Add one and cover:
  - `SpaceObserver.parseDisplay` / `appendSpaces` (pure functions,
    trivially testable with fixture dictionaries).
  - `IconCreator` with snapshot tests (e.g.
    [pointfreeco/swift-snapshot-testing]).
  - `SpacemanStyle` persistence round-trip.
- Hook tests into the CI workflow (currently only SwiftLint runs).

## 8. Localization

- UI strings are hard-coded English. Wrap in `LocalizedStringKey` /
  `String(localized:)`. Ship an initial `en.lproj/Localizable.strings`
  and accept community PRs for additional locales. Low effort, high
  polish.

## 9. Accessibility

- The status bar image is the app's only UI surface most of the time.
  Confirm `accessibilityLabel` is set on the `NSStatusItem.button` (or
  the composited `NSImage`) describing current/inactive spaces.
- Preferences window: add `.accessibilityLabel` to icon-only buttons
  (close button currently uses `Image(systemName: "xmark.circle.fill")`
  with no label).

## 10. Tooling

- Enable `SWIFTLINT` build-phase invocation for Xcode builds, not just
  CI, so developers see warnings locally.
- Consider adding `swift-format` to unify style.
- Adopt `swift package` command plugins for routine release tasks where
  scripts currently live in `scripts/release/`.

## Follow-ups

- [ ] Swift 6 / strict-concurrency migration plan.
- [ ] MenuBarExtra + Settings scene spike.
- [ ] Replace `lockFocus` with drawingHandler.
- [ ] Add XCTest target + snapshot tests.
- [ ] Add Dependabot / scheduled dependency update PRs.
