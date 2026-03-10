//
//  SessionRowView.swift
//  ResumeBar
//

import AppKit
import SwiftUI

struct SessionRowView: View {
    let session: Session
    let projectName: String?
    let displayTitle: String
    let isPinned: Bool
    let isSelected: Bool
    var snippet: String?
    var onSelect: (() -> Void)?
    var onResume: () -> Void
    var onTogglePin: () -> Void
    var onRename: (String) -> Void

    @State private var isHovered = false
    @State private var resumeFeedback = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @FocusState private var renameFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 3) {
                // Line 1: title + date
                HStack {
                    if isRenaming {
                        TextField("Session name", text: $renameText)
                            .textFieldStyle(.plain)
                            .font(Theme.title)
                            .foregroundStyle(Theme.textPrimary)
                            .focused($renameFocused)
                            .onSubmit { commitRename() }
                            .onExitCommand { cancelRename() }
                    } else {
                        Text(displayTitle)
                            .font(Theme.title)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(relativeDate(session.lastActivity))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textTertiary)
                }

                // Line 2: project · tokens · snippet | hover actions
                HStack(spacing: 4) {
                    if let projectName {
                        Text(projectName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }

                    if let tokens = session.totalTokens, tokens > 0 {
                        if projectName != nil {
                            Text("·")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text("\(SessionStore.formatTokens(tokens)) tokens")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()

                    if isHovered && !isRenaming {
                        Button {
                            onResume()
                            resumeFeedback = true
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                resumeFeedback = false
                            }
                        } label: {
                            Image(systemName: resumeFeedback ? "checkmark" : "play.fill")
                                .contentTransition(.symbolEffect(.replace))
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Theme.accent)
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }

                if let snippet {
                    highlightedSnippet(snippet)
                        .font(.system(size: 11))
                        .italic()
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, Theme.itemH)
        .padding(.vertical, Theme.itemV)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(isSelected ? Theme.cardFillHover : (isHovered ? Theme.hoverBg : .clear))
        )
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
        .onHover { hovering in isHovered = hovering }
        .contextMenu {
            Button("Rename...") { startRename() }
            Button("Copy Resume Command") {
                let command = "cd '\(session.cwd)' && claude --resume \(session.id)"
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
            }
            if !session.cwd.isEmpty {
                Button("Open Folder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: session.cwd))
                }
            }
            Divider()
            Button(isPinned ? "Unpin" : "Pin") { onTogglePin() }
        }
    }

    private func startRename() {
        renameText = displayTitle
        isRenaming = true
        renameFocused = true
    }

    private func commitRename() {
        onRename(renameText)
        isRenaming = false
    }

    private func cancelRename() {
        isRenaming = false
    }

    private func highlightedSnippet(_ raw: String) -> Text {
        var result = Text("")
        var remaining = raw[...]

        while let openBracket = remaining.firstIndex(of: "[") {
            let before = remaining[remaining.startIndex..<openBracket]
            if !before.isEmpty {
                result = result + Text(String(before))
                    .foregroundStyle(Theme.textTertiary)
            }

            let afterOpen = remaining.index(after: openBracket)
            if let closeBracket = remaining[afterOpen...].firstIndex(of: "]") {
                let matched = remaining[afterOpen..<closeBracket]
                result = result + Text(String(matched))
                    .foregroundStyle(Theme.accent)
                    .bold()
                remaining = remaining[remaining.index(after: closeBracket)...]
            } else {
                result = result + Text(String(remaining[openBracket...]))
                    .foregroundStyle(Theme.textTertiary)
                remaining = remaining[remaining.endIndex...]
            }
        }

        if !remaining.isEmpty {
            result = result + Text(String(remaining))
                .foregroundStyle(Theme.textTertiary)
        }

        return result
    }
}
