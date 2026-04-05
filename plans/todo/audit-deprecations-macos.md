# Audit — Deprecated / soft-deprecated APIs on macOS 15

Scope: APIs used by Spaceman that are deprecated, soft-deprecated, or
actively discouraged on macOS 15 Sequoia. We target macOS 15.0 as
minimum, so anything that ships a modern replacement available on
macOS ≥ 15 is fair game.

---

## 1. CoreGraphics SPI (undocumented)

**File:** `Spaceman-Bridging-Header.h`, `SpaceObserver.swift`

- `_CGSDefaultConnection`, `CGSCopyManagedDisplaySpaces`,
  `CGSCopyActiveMenuBarDisplayIdentifier` are not deprecated — they are
  not public at all. They have historically broken across macOS
  releases. Apple still has **no** public API for enumerating Spaces.
  Keep an eye on:
  - `NSWorkspace.activeSpaceDidChangeNotification` — public, used
    correctly, not going away.
  - Any public "Spaces" APIs introduced in macOS 26+ — replace the SPI
    call if one ships.
- Action: isolate SPI behind a protocol so a public replacement can be
  dropped in without rewriting the observer.

## 2. NSImage `lockFocus()` / `unlockFocus()`

**File:** `IconCreator.swift`

- Not formally deprecated, but Apple's guidance since macOS 10.8 has
  been to use `NSImage(size:flipped:drawingHandler:)`. `lockFocus`
  assumes a current graphics context and is harder to reason about with
  Retina / color management.
- Replace all `image.lockFocus(); ...; image.unlockFocus()` sites.

## 3. `NSApplication.shared.activate(ignoringOtherApps:)`

**Files:** `AppDelegate.swift`, `StatusBar.swift`

- Deprecated on macOS 14+. Replacement:
  `NSApplication.shared.activate(ignoringOtherApps:)` without the flag
  is now `activate()`. For bringing a specific window forward use
  `NSWindow.makeKeyAndOrderFront(nil)` combined with
  `NSApp.activate(ignoringOtherApps: true)` — but Xcode 16 warns on
  this. Use `NSApp.activate()` (no args) or, for the preferences
  window, `window.orderFrontRegardless()` + activation policy change.

## 4. `Timer.scheduledTimer(timeInterval:target:selector:...)`

**File:** `PreferencesViewModel.swift`

- Not deprecated, but considered legacy. Modern options:
  - Block-based `Timer.scheduledTimer(withTimeInterval:repeats:block:)`
    (no selector/target retain cycle footguns).
  - `Timer.publish(every:on:in:).autoconnect()` Combine publisher.
  - `for await _ in Timer.publish(...).values`
    (AsyncSequence).
- Recommend block-based or AsyncSequence.

## 5. `ObservableObject` / `@Published` / `@StateObject`

**Files:** `PreferencesViewModel.swift`, `PreferencesView.swift`

- Not deprecated, but superseded by the `Observation` framework
  (`@Observable`) introduced in macOS 14. Migration is mechanical and
  simplifies view diffing. Because the deployment target is 15.0, this
  is safe to adopt today.

## 6. `onChange(of:perform:)` 2-argument form

**File:** `PreferencesView.swift`

- `onChange(of:) { newValue in ... }` (single-arg closure) is
  deprecated as of macOS 14; use the 2-arg form
  `onChange(of:) { oldValue, newValue in ... }`. The codebase already
  uses the new form in most places — audit all call sites to confirm.

## 7. `PreviewProvider` protocol

**Files:** `PreferencesView.swift`, `AboutView.swift`

- Soft-deprecated in favor of the `#Preview { ... }` macro (Xcode 15+).
  Replace `struct *_Previews: PreviewProvider { ... }` with the macro.

## 8. `NSVisualEffectView` (still supported)

- Not deprecated; still the recommended way on macOS. No action. The
  wrapper in `VisualEffectView.swift` is fine.

## 9. `NSWorkspace.shared.notificationCenter`

- Not deprecated. Modern alternative for `NSWorkspace` notifications is
  the async `notifications(named:)` sequence — consider migrating as
  part of the concurrency refresh, not urgent.

## 10. `NSRunningApplication.init(processIdentifier:)`

**File:** `SpaceObserver.swift`

- Returns an optional `NSRunningApplication?`. Current usage is correct
  (`if let`). No deprecation, no action.

## 11. `NSStatusItem.variableLength`

- Current API, not deprecated. `MenuBarExtra` in SwiftUI is the modern
  alternative (tracked under `audit-state-of-the-art.md`).

## 12. `print(...)` in production code

- Not deprecated per se, but Apple strongly recommends `os.Logger`
  (macOS 11+). Migrate logging; see security audit.

## 13. `fatalError` in constant initialization

**File:** `Constants.swift`

- `fatalError("Invalid repository URL")` for a literal URL is
  defensible but crashy. Prefer `URL(string:)!` with a `#if DEBUG`
  assertion, or initialize with `URL(string:)` and handle `nil`
  gracefully at the call site.

## 14. `LSMinimumSystemVersion` via `$(MACOSX_DEPLOYMENT_TARGET)`

- Fine. No action.

## Follow-ups

- [ ] Remove all `lockFocus`/`unlockFocus` usage.
- [ ] Swap `activate(ignoringOtherApps:)` with modern activation.
- [ ] Convert `PreviewProvider` → `#Preview`.
- [ ] Replace `ObservableObject` with `@Observable`.
- [ ] Rewrite Timer usage to block-based / AsyncSequence.
- [ ] Ensure all `onChange(of:)` use the 2-arg closure form.
