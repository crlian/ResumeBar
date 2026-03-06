//
//  ChatHistoryView.swift
//  ResumeBar
//

import SwiftUI

struct ChatHistoryView: View {
    let session: Session
    let project: Project
    let store: SessionStore
    let settings: AppSettings
    var onBack: () -> Void

    @State private var messages: [ChatMessage]
    @State private var resumeFeedback = false

    init(session: Session, project: Project, store: SessionStore, settings: AppSettings, onBack: @escaping () -> Void) {
        self.session = session
        self.project = project
        self.store = store
        self.settings = settings
        self.onBack = onBack
        self._messages = State(initialValue: store.loadAllChatMessages(for: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            GradientSeparator()

            if messages.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textSecondary.opacity(0.4))
                    Text("No messages in this session")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.s) {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                chatBubble(message, index: index)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.m)
                    }
                    .frame(maxHeight: 440)
                    .onAppear {
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            GradientSeparator()
            footer
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.s) {
            Button { onBack() } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text(project.displayName)
                        .font(Theme.caption)
                }
                .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            if !messages.isEmpty {
                Text("\(messages.count) messages")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Theme.surface)
                    )
            }

            Button {
                TerminalLauncher.resume(sessionId: session.id, cwd: session.cwd, terminal: settings.terminal)
                resumeFeedback = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    resumeFeedback = false
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: resumeFeedback ? "checkmark" : "play.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.system(size: 9))
                    Text(resumeFeedback ? settings.terminal.resumeFeedbackText : "Resume")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.accent)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.itemH)
        .padding(.vertical, Spacing.s)
    }

    // MARK: - Chat Bubble

    @ViewBuilder
    private func chatBubble(_ message: ChatMessage, index: Int) -> some View {
        let isUser = message.role == .user

        HStack {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: isUser ? "person.fill" : "sparkle")
                        .font(.system(size: 9, weight: .semibold))
                    Text(isUser ? "You" : "Claude")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(isUser ? Theme.accent : Color(hex: "#8B9DC3"))
                .padding(.horizontal, 4)

                Text(message.text)
                    .font(Theme.messageBody)
                    .foregroundStyle(isUser ? Color.white : Theme.textPrimary)
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .padding(.horizontal, Spacing.s + 2)
                    .padding(.vertical, Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isUser ? Color(hex: "#3D2218") : Color(hex: "#1E1E1E"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isUser ? Theme.accent.opacity(0.3) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 0) {
            Text(store.displayTitle(for: session))
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
                .lineLimit(1)

            Spacer()

            Text("\u{238B} Back")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
    }
}
