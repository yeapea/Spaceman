# Audit — Improvements (quality, correctness, UX, maintainability)

Scope: catch-all for improvements that don't fit under security,
state-of-the-art, or deprecation audits. Organized by priority tier.

---

## Must

### M1. No automated tests
- Add an XCTest target. Cover pure logic first (`parseDisplay`,
  `appendSpaces`, `SpacemanStyle` round-trip, `spaceName` truncation).
- Wire tests into CI. Lint-only CI is not enough for a menu-bar app
  that depends on fragile SPI.

### M2. Silent failure when CGS returns unexpected data
- `SpaceObserver.updateSpaceInformation()` returns silently if
  `CGSCopyManagedDisplaySpaces` hands back an unexpected type. The
  status bar will be blank and the user will not know why.
- Add `os.Logger` error logging AND a user-visible fallback (e.g. show
  a "?" template icon on the status item) so breakage is diagnosable.

### M3. Notarization (if missing)
- See `audit-security.md` §7. A Developer-ID-signed DMG that is not
  notarized will fail Gatekeeper on first launch. Confirm and fix.

## Should

### S1. Replace stringly-typed notification
- `"ButtonPressed"` NotificationCenter name is used in 3 files. Promote
  to `extension Notification.Name { static let spacemanRefresh =
  Notification.Name("dev.jaysce.Spaceman.refresh") }`.

### S2. Memory / retain cycles
- `PreferencesViewModel.startTimer()` stores a `Timer` with `target:
  self` and `#selector(refreshSpaces)`. Timers hold strong references
  to their targets. The view model lifetime is tied to the preferences
  view, so this is unlikely to leak in practice, but switch to a
  block-based timer with `[weak self]` regardless.

### S3. `SpaceObserver` add-observer without remove
- `init` adds two observers; there is no `deinit` removing them.
  Single-instance observer makes the leak bounded, but it's still bad
  form. Add `deinit` with `NotificationCenter.default.removeObserver(self)`
  and workspace observer removal.

### S4. `displayCount` as instance state
- `IconCreator.displayCount` is a mutating instance property that is
  only meaningful inside one render call. Make it a local in
  `getIconsWithDisplayProps` and return it alongside the icons, so
  `mergeIcons` takes it as a parameter. Prevents stale values across
  calls.

### S5. Magic numbers for icon layout
- `iconSize (18×12)`, `gapWidth (5)`, `displayGapWidth (15)`, text icon
  width `49` are literals scattered throughout. Hoist to a
  `LayoutConstants` enum in `Utilities/Constants.swift`.

### S6. Force refresh button labelled "Force icon refresh shortcut"
- Clear, but cluttered. Consider a single "Refresh" button that users
  can either click or bind a shortcut to.

### S7. `SpacemanStyle.none` naming
- `none` is easy to confuse with Swift's `Optional.none`. Rename to
  `.rectangles` to match the user-facing label. Requires a migration
  note because the raw `Int` is persisted (0 stays 0, so safe).

### S8. Remove commented-out TODO
- `PreferencesView.swift` has `// Toggle("Use single icon indicator",
  isOn: .constant(false)) // TODO: Implement this`. Either implement
  or delete.

## Could

### C1. Dark/light color awareness
- `IconCreator` draws text with `NSColor.black` then marks the image
  as `isTemplate = true`, which is the correct idiom for status bar
  template images. Verify the "Numbers" style image is also marked
  template (it currently isn't in `createNumberedIcons` — the image
  never calls `iconImage.isTemplate = true`). Inconsistency.

### C2. Space-name editor UX
- The "Space" picker shows `spaceNum` values only; confusing for users
  with many spaces. Show both number and current name, e.g. `"1 — WEB"`.

### C3. 3-character limit
- 3 is arbitrary. Allow up to e.g. 6 characters and auto-scale the text
  icon width based on content. Keeps short names tight while letting
  users opt into longer ones.

### C4. Retina crispness of composed images
- `NSImage(size:)` without specifying a representation may render
  blurry on Retina. Use `NSImage(size:flipped:drawingHandler:)` or add
  an explicit `NSBitmapImageRep` at 2x.

### C5. Drop `ContentView_Previews` naming
- File headers refer to "ContentView" but the struct is
  `PreferencesView`. Rename preview struct for consistency.

### C6. Preferences window size
- Hard-coded `400×314`. Adopt intrinsic sizing (`.fixedSize()` on the
  SwiftUI root) so future content changes don't clip.

### C7. About menu view size
- `view.frame = NSRect(x: 0, y: 0, width: 220, height: 70)` hard-coded.
  Let SwiftUI size it.

### C8. Scroll / overflow for many spaces
- If a user has 20 spaces across 3 displays, the composited image may
  exceed the reasonable menu bar width. Add a max-width with
  truncation (e.g. collapse inactive spaces on non-active displays).

### C9. Documentation
- Document the CGS SPI layer inline. Add a `README` section explaining
  the architecture diagram and the data flow; link from the repo root.
- Add a `CONTRIBUTING.md` with build prerequisites.

### C10. Privacy manifest (`PrivacyInfo.xcprivacy`)
- Required for App Store distribution, optional outside — but adding
  one signals good hygiene. Declare `UserDefaults` usage and the absence
  of tracking.

## Follow-ups

- [ ] M1–M3 to become issues immediately.
- [ ] S-tier items batched into a "quality pass" PR.
- [ ] C-tier items become "good first issue" candidates.
