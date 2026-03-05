//
//  SessionsDetailView.swift
//  ResumeBar
//

import SwiftUI

struct SessionsDetailView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var settings: AppSettings
    let project: Project
    let onBack: () -> Void

    @State private var expandedSessionId: String?

    private var sessions: [Session] {
        store.filteredSessions(for: project.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text(project.displayName)
                        .font(Theme.title())
                        .lineLimit(1)
                }
                .foregroundColor(Theme.accent)
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.xs)
            }
            .buttonStyle(.plain)

            // Search bar
            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.secondaryLabelColor))
                    .font(.system(size: 12))
                TextField("Search sessions...", text: $store.sessionSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, Spacing.s)
            .frame(height: Spacing.xxxl)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.s)

            GradientSeparator()
                .padding(.horizontal, Spacing.l)

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: Spacing.s) {
                        ForEach(sessions) { session in
                            sessionCard(session)
                        }
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.vertical, Spacing.s)
                }
                .frame(maxHeight: 480)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(Color(.quaternaryLabelColor))
            Text("No matching sessions")
                .foregroundColor(Color(.secondaryLabelColor))
                .font(Theme.caption())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func sessionCard(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Session header row
            HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(.labelColor))
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Text(store.relativeDate(session.lastActivity))
                        .font(Theme.caption())
                        .foregroundColor(Color(.tertiaryLabelColor))
                }

                Spacer()

                // Preview button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if expandedSessionId == session.id {
                            expandedSessionId = nil
                        } else {
                            expandedSessionId = session.id
                        }
                    }
                } label: {
                    Image(systemName: expandedSessionId == session.id ? "eye.fill" : "eye")
                        .font(.system(size: 13))
                        .foregroundColor(expandedSessionId == session.id ? Theme.accent : Color(.secondaryLabelColor))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Resume button
                Button {
                    TerminalLauncher.resume(sessionId: session.id, cwd: session.cwd, terminal: settings.terminal)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Theme.accent)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.m)

            // Expanded chat preview
            if expandedSessionId == session.id {
                let result = store.loadChatMessages(for: session, limit: 8)
                if !result.messages.isEmpty {
                    ChatPreviewView(messages: result.messages, totalCount: result.totalCount)
                        .padding(.horizontal, Spacing.m)
                        .padding(.bottom, Spacing.m)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
        }
        .cardStyle()
        .hoverEffect()
    }
}
