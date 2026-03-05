//
//  TerminalLauncher.swift
//  ResumeBar
//

import Foundation

struct TerminalLauncher {
    static func resume(sessionId: String, cwd: String, terminal: String) {
        let escapedDir = cwd.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "'", with: "'\\''")

        var script: String

        if terminal == "Ghostty" {
            let escaped = cwd.replacingOccurrences(of: "'", with: "'\\''")
            let tmpFile = URL(fileURLWithPath: "/tmp/resumebar-\(sessionId).sh")
            let scriptContent = "#!/bin/sh\ncd '\(escaped)' && claude --resume \(sessionId)\nexec $SHELL"
            do {
                try scriptContent.write(to: tmpFile, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmpFile.path)
            } catch {
                print("Failed to write script: \(error)")
                return
            }
            let shellCmd = "open -na Ghostty --args -e \(tmpFile.path)"
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", shellCmd]
            try? task.run()
            return
        } else if terminal == "iTerm2" {
            let cmd = "cd '" + cwd.replacingOccurrences(of: "'", with: "'\\''") + "' && claude --resume " + sessionId
            script = "tell application \"iTerm2\" to create window with default profile command \"" + cmd.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
        } else {
            let cmd = "cd \\\"" + escapedDir + "\\\" && claude --resume " + sessionId
            script = "tell application \"Terminal\"\n" +
                "do script \"" + cmd + "\"\n" +
                "activate\n" +
                "end tell"
        }

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error {
                print("AppleScript error: \(error)")
            }
        }
    }
}
