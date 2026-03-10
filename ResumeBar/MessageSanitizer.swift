//
//  MessageSanitizer.swift
//  ResumeBar

import Foundation

enum MessageSanitizer {

    // Tags whose entire block (tag + content) should be removed
    private static let stripTags: [String] = [
        "system-reminder",
        "available-deferred-tools",
        "antml:thinking",
        "antml:function_calls",
        "command-name",
        "command-args",
        "command-message",
        "persisted-output",
        "tool_use_error",
        "fast_mode_info",
        "local-command-caveat",
        "local-command-stdout",
    ]

    private static let stripPatterns: [NSRegularExpression] = {
        stripTags.compactMap { tag in
            // Match <tag>...content...</tag> including newlines
            try? NSRegularExpression(
                pattern: "<\(NSRegularExpression.escapedPattern(for: tag))>[\\s\\S]*?</\(NSRegularExpression.escapedPattern(for: tag))>",
                options: []
            )
        }
    }()

    static func clean(_ text: String) -> String? {
        var result = text

        for pattern in stripPatterns {
            result = pattern.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}
