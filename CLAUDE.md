# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

Requires Xcode 26+ and macOS 26+.

```bash
# Build from command line
xcodebuild -scheme ResumeBar -configuration Debug build

# Or open in Xcode and Cmd+R
open ResumeBar.xcodeproj
```

There are no tests, linter, or CI pipeline configured.

## Architecture

ResumeBar is a macOS menu bar app that lets you browse and resume Claude Code sessions. It reads `.jsonl` session files from `~/.claude/projects/` and launches `claude --resume <session-id>` in the user's terminal.

### Swift/Xcode Configuration

- **Deployment target:** macOS 26.2
- **Swift concurrency:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` — all code is MainActor-isolated by default, no need for explicit `@MainActor` annotations
- **File sync:** Uses `PBXFileSystemSynchronizedRootGroup` — new `.swift` files in `ResumeBar/` are auto-discovered by Xcode (no manual project file edits needed)
- **Color scheme:** Forces `.preferredColorScheme(.dark)` — dark-only app

### Data Flow

```
~/.claude/projects/<encoded-path>/<session-id>.jsonl
        ↓
    SessionStore (@Observable)
    - Parses JSONL → Project/Session models
    - Watches directory via DispatchSource file system events
    - Caches chat preview messages
        ↓
    Views (SwiftUI)
```

`SessionStore` is the single source of truth. It loads all session data on init and reloads when the watched directory changes. Chat messages are lazily loaded and cached per session.

### Navigation

The app uses a manual ZStack-based navigation (not NavigationStack):

```
ContentView (ZStack with slide transitions)
  ├── HomeView: search bar, pinned sessions, recent sessions, project list
  └── ProjectDetailView: session list for one project, chat preview expand
```

Navigation state is a simple `NavigationScreen` enum in `ContentView`. Escape key goes back or closes the window.

### Persistence

- **Session data:** Read-only from `~/.claude/projects/` (owned by Claude Code)
- **Aliases:** `~/Library/Application Support/ResumeBar/session-aliases.json` (AliasStore)
- **Pins:** `~/Library/Application Support/ResumeBar/pinned-sessions.json` (PinStore)
- **Settings:** `@AppStorage` in UserDefaults (AppSettings)

### Key Patterns

- All `@Observable` classes (`SessionStore`, `AliasStore`, `PinStore`, `AppSettings`) are injected from `ResumeBarApp` and passed down as parameters — no environment objects
- `Theme` enum centralizes all colors (Claude dark palette with coral accent `#D77757`), typography, and spacing constants
- `CardStyle` and `HoverModifier` are reusable view modifiers applied via `.cardStyle()` and `.hoverEffect()`
- `TerminalLauncher` supports Terminal.app (AppleScript), iTerm2 (AppleScript), and Ghostty (temp shell script + `open -na`)
