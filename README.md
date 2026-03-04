# ResumeBar

ResumeBar is a lightweight macOS menu bar app for Claude Code users.

It lets you quickly browse past sessions by project and resume them in one click from Terminal/iTerm — without digging through folders or old terminal tabs.

## Why

If you use Claude Code daily, context switching is painful.
Resuming old sessions should be instant.

ResumeBar is built to make that flow simple:
- open from menu bar
- find session by project
- resume immediately

## MVP Scope

- [x] macOS menu bar app (MenuBarExtra)
- [ ] List local Claude Code sessions by project
- [ ] Show recent sessions with timestamp
- [ ] One-click resume: `claude --resume <session-id>`
- [ ] Terminal app preference (Terminal / iTerm)

## Out of Scope (for MVP)

- AI-generated summaries
- Full-text search
- Analytics
- Windows/Linux support

## How it works (planned)

ResumeBar reads local Claude session files from:

`~/.claude/projects/<path-encoded>/<session-id>.jsonl`

Then it:
1. groups sessions by project
2. shows recent entries in menu bar dropdown
3. opens terminal and runs `claude --resume <id>`

## Status

🚧 Early build in progress.

## Feedback welcome

If you use Claude Code and this would save you time, open an issue or drop feedback.

---

Not affiliated with Anthropic.
