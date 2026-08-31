# CLAUDE.md

Guidance for Claude Code (and other AI assistants) when working in this repository.

## Project overview

**Spaceman** is a macOS menu-bar utility (LSUIElement) that visualizes macOS
Spaces / Virtual Desktops. It shows the currently active space, inactive
spaces, fullscreen apps, and per-display grouping in the system status bar.
Users can pick from several render styles (rectangles, numbers, combined, or
named spaces) and assign up to 3-character names to individual spaces.

- Minimum OS: macOS 15 Sequoia (`MACOSX_DEPLOYMENT_TARGET = 15.0`)
- Language: Swift 5.0, SwiftUI + AppKit interop
- App type: Status bar app, sandboxed, hardened runtime enabled
- Uses **private CoreGraphics SPI** (`CGSCopyManagedDisplaySpaces`,
  `_CGSDefaultConnection`) via an Objective-C bridging header to enumerate
  Spaces. This is the core reason the app exists and the main source of
  fragility across macOS updates.
- Distributed outside the App Store via GitHub Releases with Sparkle 2
  auto-updates (EdDSA signed appcast).

### Architecture

```
Spaceman/
  AppDelegate.swift             # App entry, wires StatusBar + SpaceObserver + IconCreator
  Spaceman-Bridging-Header.h    # Private CGS SPI declarations
  Extensions.swift              # NSString drawing helper, KeyboardShortcuts.Name
  Helpers/
    SpaceObserver.swift         # Polls CGS, builds [Space] model, persists names in UserDefaults
    IconCreator.swift           # Renders composited NSImage template icons per style
  Model/
    Space.swift                 # Per-space value type
    SpaceNameInfo.swift         # Persisted name payload (Codable)
    SpacemanStyle.swift         # Style enum (raw Int stored in UserDefaults)
  View/
    StatusBar.swift             # NSStatusItem + menu, Sparkle updater controller
    PreferencesView.swift       # SwiftUI preferences pane
    PreferencesWindow.swift     # NSWindow host for SwiftUI preferences
    AboutView.swift             # Menu "about" header view
    VisualEffectView.swift      # NSVisualEffectView wrapper
  ViewModel/
    PreferencesViewModel.swift  # Preferences state + auto-refresh Timer
  Utilities/
    Constants.swift             # URLs, version string
```

Data flow: `SpaceObserver` listens for `NSWorkspace.activeSpaceDidChangeNotification`
and an internal `"ButtonPressed"` NotificationCenter name. It queries CGS,
produces `[Space]`, and forwards to `AppDelegate`, which asks `IconCreator` to
compose an `NSImage` that `StatusBar` assigns to the `NSStatusItem` button.

### Dependencies (SwiftPM)

- Sparkle 2.8.1 (auto-updates, EdDSA)
- sindresorhus/KeyboardShortcuts 2.4.0
- sindresorhus/LaunchAtLogin-Modern 1.1.0

## Language policy

**All artifacts committed to this repository MUST be in English.** This
applies to:

- Source code, identifiers, and code comments
- Commit messages, branch names, PR titles and descriptions
- Markdown files (README, CHANGELOG, plans, docs)
- Issue templates, workflow files, scripts

Conversations with the user may be held in German, but nothing German-language
may land in the repository. If the user dictates German text that needs to
enter the repo, translate it to English before committing.

## Repository hygiene

- The repository is **public**. Do **not** commit chat transcripts, session
  logs, screenshots of the Claude UI, internal prompts, or any information
  that is clearly conversational rather than a deliverable.
- Keep the tree clean: no scratch files, personal notes, or TODO dumps in the
  root. Planning artifacts belong under `plans/`.
- Do not introduce secrets. CI secrets are injected via GitHub Actions
  (`APPLE_*`, `SPARKLE_PRIVATE_ED_KEY`, etc.) — never commit their values.

## Planning workflow

- `PLAN.md` (repo root) is the index of active planning documents.
- `plans/todo/` contains active plan documents that still need work.
- `plans/archive/` contains completed or obsolete plans.
- Plans are written in English Markdown, chunked into small self-contained
  files to avoid long-running generation timeouts.
- When a plan is completed, move it from `plans/todo/` to `plans/archive/`
  rather than deleting it, so history is preserved.

## Build & lint

- Build via Xcode or `xcodebuild -project Spaceman.xcodeproj -scheme Spaceman`.
- Lint: `swiftlint lint Spaceman --config .swiftlint.yml --strict` (matches CI).
- CI runs on `macos-15` and must stay green on `main`.

## Working conventions for AI assistants

- Prefer surgical edits over sweeping refactors unless explicitly asked.
- When touching the CGS SPI layer or icon rendering, document assumptions in
  comments — this code is undocumented Apple private API.
- Use the existing style conventions from surrounding files (SwiftLint rules
  in `.swiftlint.yml`).
- When adding files, place them in the matching `Model / View / ViewModel /
  Helpers / Utilities` folder and add them to the Xcode project.
