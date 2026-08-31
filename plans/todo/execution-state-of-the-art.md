# State-of-the-Art Migration — Execution Plan

Working branch: `claude/setup-docs-planning-Im7eV`.
CI (`macos-15`) validates each push.

## Phases

### Phase 1 — Strict tooling foundation (no Swift code touched)
- Tighten `.swiftlint.yml` (more opt-in rules, analyzer rules, strict mode
  already on).
- Add `.swift-format` config + CI check.
- Add `.github/dependabot.yml` for SwiftPM + GitHub Actions weekly updates.
- Add SwiftLint build-phase script in Xcode so warnings surface locally.
- Add CI test job scaffolding (runs once test target exists).

### Phase 2 — XCTest target
- Add `SpacemanTests` target via careful pbxproj edit.
- Add first tests for pure logic:
  - `SpacemanStyleTests` (raw-value persistence round-trip).
  - `SpaceObserverParsingTests` (parse fixture CGS dictionaries).
  - `SpaceNameInfoTests` (Codable round-trip, 3-char truncation).
- Wire tests into CI workflow.

### Phase 3 — Swift code modernization (safe, surgical)
- `print` → `os.Logger` with subsystem `dev.jaysce.Spaceman`.
- `"ButtonPressed"` string → typed `Notification.Name.spacemanRefresh`.
- `PreferencesViewModel`: block-based Timer with `[weak self]`,
  `deinit` invalidates timer.
- `SpaceObserver`: `deinit` removes observers.
- `IconCreator`: fix missing `isTemplate = true` in `createNumberedIcons`.
- `IconCreator.displayCount`: move from instance → local return value.
- `PreviewProvider` → `#Preview` macro.
- `SpacemanStyle.none` → `SpacemanStyle.rectangles` (raw value 0 stays).
- `fatalError` in `Constants` → safer construction.
- Unused entitlement + unused SPI declaration removed.

### Phase 4 — Observation / concurrency
- `PreferencesViewModel` (`ObservableObject`) → `@Observable`.
- `PreferencesView` `@StateObject` → `@State`.
- `@AppStorage("displayStyle")` + `RawRepresentable` `SpacemanStyle`.
- Annotate AppKit-touching classes `@MainActor`.
- Bump `SWIFT_VERSION` to 5.10; enable `SWIFT_STRICT_CONCURRENCY = minimal`
  first, iterate up.

### Phase 5 — Drawing pipeline
- Replace `lockFocus`/`unlockFocus` with
  `NSImage(size:flipped:drawingHandler:)`.
- Ensure Retina-correct sizing.

### Phase 6 — SwiftUI architecture (larger, separate PR scope)
- `MenuBarExtra` spike to replace `NSStatusItem` wrapper.
- Promote preferences fully into `Settings` scene; retire
  `PreferencesWindow`.

Phases 1–5 land on `claude/setup-docs-planning-Im7eV`.
Phase 6 gets its own branch/PR once 1–5 are green on CI.

## Verification strategy

- I cannot build locally. Every push runs CI lint.
- Once the test target exists, CI will also compile + run tests.
- If CI fails, fix-forward with a follow-up commit.
