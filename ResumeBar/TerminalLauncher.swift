//
//  TerminalLauncher.swift
//  ResumeBar
//

import AppKit
import Foundation

enum SupportedTerminal: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm2 = "iTerm2"
    case ghostty = "Ghostty"
    case kitty = "Kitty"
    case wezterm = "WezTerm"
    case warp = "Warp"
    case alacritty = "Alacritty"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .terminal: "Terminal.app"
        case .iterm2: "iTerm2"
        case .ghostty: "Ghostty"
        case .kitty: "Kitty"
        case .wezterm: "WezTerm"
        case .warp: "Warp"
        case .alacritty: "Alacritty"
        }
    }

    var resumeFeedbackText: String {
        switch self {
        case .warp: "Cmd copied"
        default: "Launched"
        }
    }
}

struct TerminalLauncher {

    // MARK: - Public

    static func resume(sessionId: String, cwd: String, terminal: SupportedTerminal) {
        switch terminal {
        case .terminal: launchTerminalApp(sessionId: sessionId, cwd: cwd)
        case .iterm2: launchITerm2(sessionId: sessionId, cwd: cwd)
        case .ghostty: launchGhostty(sessionId: sessionId, cwd: cwd)
        case .kitty: launchKitty(sessionId: sessionId, cwd: cwd)
        case .wezterm: launchWezTerm(sessionId: sessionId, cwd: cwd)
        case .warp: launchWarp(sessionId: sessionId, cwd: cwd)
        case .alacritty: launchAlacritty(sessionId: sessionId, cwd: cwd)
        }
    }

    // MARK: - AppleScript Terminals

    private static func launchTerminalApp(sessionId: String, cwd: String) {
        let cmd = appleScriptEscape("cd '\(shellEscape(cwd))' && claude --resume \(sessionId)")
        let script = """
        tell application "Terminal"
            if (count of windows) > 0 then
                activate
                tell application "System Events" to keystroke "t" using {command down}
                delay 0.3
                do script "\(cmd)" in front window
            else
                do script "\(cmd)"
                activate
            end if
        end tell
        """
        runAppleScript(script)
    }

    private static func launchITerm2(sessionId: String, cwd: String) {
        let cmd = appleScriptEscape("cd '\(shellEscape(cwd))' && claude --resume \(sessionId)")
        let script = """
        tell application "iTerm"
            if (count of windows) > 0 then
                tell current window
                    create tab with default profile
                    tell current session to write text "\(cmd)"
                end tell
            else
                create window with default profile
                tell current window
                    tell current session to write text "\(cmd)"
                end tell
            end if
            activate
        end tell
        """
        runAppleScript(script)
    }

    // MARK: - Process-based Terminals

    private static func launchGhostty(sessionId: String, cwd: String) {
        // Ghostty's -e only accepts a single argument (the executable path),
        // so we write a small launch script that -e can point to.
        let escaped = shellEscape(cwd)
        let scriptPath = "/tmp/resumebar-\(sessionId).sh"
        let scriptContent = "#!/bin/zsh -l\ncd '\(escaped)' && claude --resume \(sessionId)\nexec $SHELL\n"

        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
        } catch {
            print("Failed to write Ghostty launch script: \(error)")
            return
        }

        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-na", "Ghostty", "--args", "-e", scriptPath]
            try? process.run()
        }
    }

    private static func launchKitty(sessionId: String, cwd: String) {
        let cmd = "claude --resume \(sessionId)"
        Task.detached {
            // Try tab via remote control first
            let kitten = Process()
            kitten.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            kitten.arguments = ["kitten", "@", "launch", "--type=tab", "--cwd", cwd, "--", "/bin/zsh", "-l", "-c", cmd]
            kitten.standardOutput = FileHandle.nullDevice
            kitten.standardError = FileHandle.nullDevice
            do {
                try kitten.run()
                kitten.waitUntilExit()
                if kitten.terminationStatus == 0 { return }
            } catch {}

            // Fallback: launch new window
            let kitty = Process()
            kitty.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            kitty.arguments = ["kitty", "--directory", cwd, "/bin/zsh", "-l", "-c", cmd]
            try? kitty.run()
        }
    }

    private static func launchWezTerm(sessionId: String, cwd: String) {
        let cmd = "claude --resume \(sessionId)"
        Task.detached {
            // Try tab in existing instance
            let cli = Process()
            cli.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            cli.arguments = ["wezterm", "cli", "spawn", "--cwd", cwd, "--", "/bin/zsh", "-l", "-c", cmd]
            cli.standardOutput = FileHandle.nullDevice
            cli.standardError = FileHandle.nullDevice
            do {
                try cli.run()
                cli.waitUntilExit()
                if cli.terminationStatus == 0 { return }
            } catch {}

            // Fallback: start new instance
            let start = Process()
            start.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            start.arguments = ["wezterm", "start", "--cwd", cwd, "--", "/bin/zsh", "-l", "-c", cmd]
            try? start.run()
        }
    }

    private static func launchWarp(sessionId: String, cwd: String) {
        let cmd = "cd '\(shellEscape(cwd))' && claude --resume \(sessionId)"

        // Copy command to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cmd, forType: .string)

        // Open tab (or window if not running) via URI scheme
        let encodedPath = cwd.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cwd
        if let url = URL(string: "warp://action/new_tab?path=\(encodedPath)") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func launchAlacritty(sessionId: String, cwd: String) {
        let cmd = "claude --resume \(sessionId)"
        Task.detached {
            // Try IPC to existing instance
            let msg = Process()
            msg.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            msg.arguments = ["alacritty", "msg", "create-window", "--working-directory", cwd, "-e", "/bin/zsh", "-l", "-c", cmd]
            msg.standardOutput = FileHandle.nullDevice
            msg.standardError = FileHandle.nullDevice
            do {
                try msg.run()
                msg.waitUntilExit()
                if msg.terminationStatus == 0 { return }
            } catch {}

            // Fallback: fresh instance
            let fresh = Process()
            fresh.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            fresh.arguments = ["alacritty", "--working-directory", cwd, "-e", "/bin/zsh", "-l", "-c", cmd]
            try? fresh.run()
        }
    }

    // MARK: - Helpers

    /// Escapes a string for use inside single quotes in shell commands.
    private static func shellEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "'", with: "'\\''")
    }

    /// Escapes a string for embedding inside an AppleScript double-quoted string.
    private static func appleScriptEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func runAppleScript(_ source: String) {
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error {
                print("AppleScript error: \(error)")
            }
        }
    }
}
