# Contributing to ResumeBar

Thanks for your interest in contributing! ResumeBar is a small macOS menu bar app and contributions of all sizes are welcome.

## Getting started

1. Fork and clone the repo
2. Open `ResumeBar.xcodeproj` in Xcode 26+
3. Build and run (`Cmd+R`)

The app reads sessions from `~/.claude/projects/` — you'll need Claude Code installed with some session history to see data.

## Project structure

```
ResumeBar/
├── ResumeBarApp.swift        # Entry point, MenuBarExtra + Settings
├── ContentView.swift         # Navigation container with slide transitions
├── ProjectsListView.swift    # Project cards with search
├── SessionsDetailView.swift  # Session cards with resume + preview
├── ChatPreviewView.swift     # Inline chat message preview
├── SessionStore.swift        # Data layer, file watcher, JSONL parsing
├── SessionModel.swift        # Session, Project, ChatMessage models
├── TerminalLauncher.swift    # Opens terminal with claude --resume
├── AppSettings.swift         # @AppStorage preferences
├── SettingsView.swift        # Settings form
├── Theme.swift               # Colors, typography, card styles
└── MenuBarIcon.swift         # Menu bar icon
```

## How to contribute

- **Bug reports** — open an issue with steps to reproduce
- **Feature requests** — open an issue describing the use case
- **Pull requests** — fork, create a branch, make your changes, open a PR

### Pull request guidelines

- Keep PRs focused on a single change
- Test on macOS 26+ before submitting
- Follow the existing code style (SwiftUI, `@MainActor` isolation)

## Ideas for contributions

- Keyboard shortcuts for navigation
- Session pinning / favorites
- Dark/light mode refinements
- Accessibility improvements
- Localization

## Questions?

Open an issue — happy to help.
