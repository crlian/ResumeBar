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
    var onResume: () -> Void
    var onTogglePin: () -> Void
    var onDelete: () -> Void
    var onRename: (String) -> Void

    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    @State private var resumeFeedback = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @FocusState private var renameFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    if let projectName {
                        Text(projectName)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.projectColor(for: projectName))
                        Text("\u{2014}")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }

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
                }

                if !session.preview.isEmpty && !isRenaming {
                    Text(session.preview)
                        .font(Theme.preview)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isHovered && !isRenaming {
                Text(relativeDate(session.lastActivity))
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .transition(.opacity)

                Button {
                    startRename()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity)

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
        .padding(.horizontal, Theme.itemH)
        .padding(.vertical, Theme.itemV)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(isSelected ? Theme.cardFillHover : (isHovered ? Theme.hoverBg : .clear))
        )
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .onHover { hovering in isHovered = hovering }
        .contextMenu {
            Button("Resume Session") { onResume() }
            Button("Rename...") { startRename() }
            Button("Copy First Prompt") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(session.title, forType: .string)
            }
            if !session.cwd.isEmpty {
                Button("Open Folder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: session.cwd))
                }
            }
            Divider()
            Button(isPinned ? "Unpin" : "Pin") { onTogglePin() }
            Divider()
            Button("Delete Session", role: .destructive) { showDeleteConfirm = true }
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This will permanently delete the session file.")
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
}
