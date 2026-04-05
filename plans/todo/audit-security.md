# Audit — Security

Scope: security posture of the Spaceman macOS app as currently in `main`.
Deployment target is macOS 15, the app is sandboxed with hardened runtime,
and it ships outside the App Store via Sparkle auto-updates.

Findings are grouped by topic. Severity is informal (Low / Med / High).
Each item should eventually become an issue or a commit.

---

## 1. Private CoreGraphics SPI surface

**Files:** `Spaceman/Spaceman-Bridging-Header.h`,
`Spaceman/Helpers/SpaceObserver.swift`

- `_CGSDefaultConnection`, `CGSCopyManagedDisplaySpaces`,
  `CGSCopyActiveMenuBarDisplayIdentifier` are undocumented CoreGraphics SPI.
  Apple can remove or lock these behind entitlements at any point — already
  happened in the Sequoia beta cycle for neighboring CGS calls.
- `CGSCopyActiveMenuBarDisplayIdentifier` is declared but never used —
  remove it to reduce the private-API surface that App Review / static
  scanners will flag. **Severity: Low.**
- Return values are force-cast via `as?` with only partial guards. A shape
  change in the returned dictionaries (e.g. `"Current Space"` key renamed)
  silently returns `nil` and the menu bar goes blank. Add structured
  logging (os.Logger, not `print`) so users can report breakage.
  **Severity: Med.**
- Consider gating the SPI behind a thin wrapper that exposes only typed
  results, so the unsafe layer is auditable in one place.

## 2. Sandbox & entitlements

**File:** `Spaceman/Spaceman.entitlements`

```
com.apple.security.app-sandbox                          = true
com.apple.security.files.user-selected.read-only        = true
com.apple.security.network.client                       = true
```

- `files.user-selected.read-only` is declared but the app never shows an
  `NSOpenPanel`. Drop it; unused entitlements are a policy smell and can
  confuse App Review / notarization. **Severity: Low.**
- `network.client` is needed for Sparkle update checks. Document this in a
  comment next to the entitlement (entitlements plists don't support XML
  comments cleanly — document in `CLAUDE.md` or `RELEASING.md`). Consider
  scoping reachable hosts via NSAppTransportSecurity exceptions only if
  tightening is ever needed; current setup is fine.
- `LSUIElement=true` is correct (agent app, no Dock icon).
- Hardened runtime is on (`ENABLE_HARDENED_RUNTIME = YES`). Good.

## 3. Sparkle update channel

**Files:** `Spaceman/Info.plist`, `Spaceman/View/StatusBar.swift`,
`.github/workflows/release.yml`

- `SUFeedURL` points at
  `https://github.com/Jaysce/Spaceman/releases/latest/download/appcast.xml`
  served over HTTPS. Good.
- `SUPublicEDKey` is pinned in `Info.plist` (EdDSA). The private key is a
  GitHub Actions secret (`SPARKLE_PRIVATE_ED_KEY`). Good — this is the
  Sparkle 2 recommended setup.
- The `/latest/download/` redirect pattern means every new release
  overwrites the feed URL contents. Make sure the CI job that regenerates
  `appcast.xml` always re-signs with the pinned key and verify `sparkle:
  edSignature` presence before upload. Add a post-upload verification step
  that fetches the published appcast and checks signatures match the
  pinned public key. **Severity: Med.**
- Sparkle 2.8.1 is current at time of writing; schedule a dependency sweep
  (see `audit-state-of-the-art.md`).
- Recommend enabling Sparkle's installer XPC services for permission-less
  updates if not already (check the build config and Sparkle framework
  embed options).

## 4. UserDefaults as data store

**Files:** `SpaceObserver.swift`, `PreferencesView.swift`,
`PreferencesViewModel.swift`

- Space-name metadata is encoded with `PropertyListEncoder` and stored
  under key `"spaceNames"` in `UserDefaults.standard`.
- No PII or secrets stored — low risk surface. However:
  - User-supplied names are used verbatim in the rendered menu bar image
    (drawn via CoreGraphics). There is no XSS/script vector, but confirm
    that extremely long strings are always truncated to 3 chars before
    render (currently enforced in the TextField setter, but not at the
    model layer — belt-and-braces validation missing).
  - Decode is `try?`-swallowed, so a corrupted plist silently resets
    names. Log the failure through `os.Logger` to make support easier.
- Consider namespacing the `"spaceNames"` key (`app.spaceman.spaceNames`)
  or migrating to a typed `@AppStorage` + `Codable` wrapper. **Severity:
  Low.**

## 5. NotificationCenter string names

**Files:** `SpaceObserver.swift`, `PreferencesView.swift`,
`PreferencesViewModel.swift`

- A stringly-typed `"ButtonPressed"` notification crosses several layers.
  Any other process that posts through the default center cannot reach
  this one (it's `NotificationCenter.default`, not distributed), so this
  is not an attack vector — but it is a footgun. Promote to a typed
  `Notification.Name` extension. **Severity: Low (defensive hygiene).**

## 6. Supply chain

**File:** `Spaceman.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

Pinned dependencies:

- `Sparkle 2.8.1`
- `KeyboardShortcuts 2.4.0`
- `LaunchAtLogin-Modern 1.1.0`

Actions:

- Add a recurring CI job (Dependabot or a `swift package update` dry-run)
  that opens PRs when a new dependency version is available. **Severity:
  Low.**
- Pin by exact version in the Xcode project (`.upToNextMajor` is fine, but
  verify none of these resolve to unexpected majors on CI refresh).
- All three packages are from reputable authors and are widely used; no
  immediate concerns.
- `Package.resolved` (v3) is committed to the repo — good, required for
  reproducible builds.

## 7. Code signing / notarization workflow

**File:** `.github/workflows/release.yml`

- Developer ID cert is imported from `APPLE_DEVELOPER_ID_CERT_P12_BASE64`,
  password from `APPLE_DEVELOPER_ID_CERT_PASSWORD`. Keychain password from
  `APPLE_KEYCHAIN_PASSWORD`. All via GitHub secrets. Good.
- Temporary keychain is created under `$RUNNER_TEMP` and added to search
  list. Clean up step is not visible in the excerpt — confirm the keychain
  is deleted at the end of the job (or is discarded with the runner).
- Missing: notarization + stapling. A "Developer ID signed" build is not
  the same as a notarized build — macOS Gatekeeper requires notarization
  for first-launch without the right-click override. Verify that
  `build_dmg.sh` or a follow-up step calls `notarytool submit --wait` and
  `stapler staple`. If not, this is **Severity: High** for distribution
  hygiene.
- Consider moving to short-lived App Store Connect API keys for
  notarization instead of an Apple ID password.

## 8. Logging / telemetry

- `print(...)` is used in `SpaceObserver` and `PreferencesViewModel`.
  These go to unified logging as `Default` subsystem `com.apple.swift`.
  Migrate to `os.Logger(subsystem: "dev.jaysce.Spaceman", category: ...)`
  so messages are attributable, filterable, and redaction-aware.
  **Severity: Low.**
- No analytics / telemetry is shipped — that is a privacy win, keep it.

## Follow-ups

- [ ] Open issues for the Med-severity items (SPI hardening, Sparkle
      post-publish verification).
- [ ] Verify notarization/stapling exists in release scripts.
- [ ] Remove unused entitlement and unused SPI declaration.
- [ ] Replace `print` with `os.Logger`.
