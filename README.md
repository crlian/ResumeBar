# ResumeBar

[![GitHub release](https://img.shields.io/github/v/release/crlian/ResumeBar?include_prereleases&style=flat-square&logo=github)](https://github.com/crlian/ResumeBar/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-26%2B-black?style=flat-square&logo=apple)](https://github.com/crlian/ResumeBar)
[![GitHub stars](https://img.shields.io/github/stars/crlian/ResumeBar?style=flat-square)](https://github.com/crlian/ResumeBar/stargazers)

A macOS menu bar app to browse, search, and resume Claude Code sessions.

## Why

Resuming Claude Code sessions is painful — you have to remember session IDs, dig through terminal history, or navigate `~/.claude/projects/` manually.

ResumeBar puts every session one click away from your menu bar.

## Features

### Core
- **Menu bar app** — always accessible, zero window management
- **Project browser** — all projects with session counts and last activity
- **Session list** — sorted by recency with token usage and file change stats
- **Chat history** — read the full conversation for any session
- **One-click resume** — launches `claude --resume <session-id>` in your terminal

### Search
- **Title search** — instant filtering by project name, session title, or alias
- **Full-text search** — SQLite FTS5 index over all chat messages, triggered at 3+ characters
- **Ranked results** — snippets with highlighted matches, click to jump to the matching message
- **Background indexing** — sessions are indexed on launch and on file changes, without blocking the UI

### Organization
- **Pin sessions** — keep important sessions at the top
- **Rename sessions** — assign meaningful names via aliases
- **Auto-refresh** — watches `~/.claude/projects/` for changes via file system events

### Terminal support
- Terminal.app
- iTerm2
- Ghostty
- Warp

## Installation

### Download

Grab the latest `.zip` from [GitHub Releases](../../releases) and drag `ResumeBar.app` to your Applications folder.

> **Note:** The app is not signed or notarized. On first launch:
> ```bash
> xattr -cr /Applications/ResumeBar.app
> ```

### Build from source

Requires Xcode 26+ and macOS 26+.

```bash
git clone https://github.com/crlian/ResumeBar.git
cd ResumeBar
open ResumeBar.xcodeproj
```

Build and run with `Cmd+R`.

## How it works

ResumeBar reads Claude Code session files from `~/.claude/projects/` and parses each `.jsonl` file to extract session metadata, chat messages, token usage, and file changes.

On first launch, all messages are indexed into a local SQLite FTS5 database (`~/Library/Application Support/ResumeBar/search.db`) for full-text search. The index updates incrementally when sessions change.

When you click Resume, it opens a new terminal window, `cd`s to the project directory, and runs `claude --resume <session-id>`.

## Architecture

```
~/.claude/projects/<encoded-path>/<session-id>.jsonl
        ↓
    SessionStore — parses JSONL, watches directory, caches messages
    SearchIndex  — SQLite FTS5 full-text search over all messages
        ↓
    SwiftUI views — MenuBarExtra with ZStack navigation
```

### Data storage

| Data | Location |
|------|----------|
| Sessions | `~/.claude/projects/` (read-only, owned by Claude Code) |
| Search index | `~/Library/Application Support/ResumeBar/search.db` |
| Aliases | `~/Library/Application Support/ResumeBar/session-aliases.json` |
| Pins | `~/Library/Application Support/ResumeBar/pinned-sessions.json` |
| Settings | UserDefaults via `@AppStorage` |

## Requirements

- macOS 26 or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT

---

Not affiliated with Anthropic.
