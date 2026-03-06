//
//  ProjectDetailView.swift
//  ResumeBar
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    let store: SessionStore
    let pinStore: PinStore
    let aliasStore: AliasStore
    let settings: AppSettings

    var onBack: () -> Void

    @State private var expandedSessionId: String?
    @State private var chatMessages: [String: ([ChatMessage], Int)] = [:]

    private var sessions: [Session] {
        let query = store.searchText.lowercased()
        if query.isEmpty { return project.sessions }
        return project.sessions.filter {
            store.displayTitle(for: $0).lowercased().contains(query)
                || $0.title.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back header
            Button { onBack() } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Circle()
                        .fill(Theme.projectColor(for: project.displayName))
                        .frame(width: 8, height: 8)
                    Text(project.displayName)
                        .font(Theme.projectName)
                    Spacer()
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Theme.itemH)
                .padding(.vertical, Spacing.m)
            }
            .buttonStyle(.plain)

            GradientSeparator()

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    Text("No matching sessions")
                        .foregroundStyle(Theme.textSecondary)
                        .font(Theme.caption)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sessions) { session in
                            VStack(alignment: .leading, spacing: 0) {
                                SessionRowView(
                                    session: session,
                                    projectName: nil,
                                    displayTitle: store.displayTitle(for: session),
                                    isPinned: pinStore.isPinned(session.id),
                                    isSelected: false,
                                    onResume: { resumeSession(session) },
                                    onTogglePin: { pinStore.toggle(session.id) },
                                    onDelete: { store.deleteSession(session) },
                                    onRename: { aliasStore.set($0, for: session.id) }
                                )
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if expandedSessionId == session.id {
                                            expandedSessionId = nil
                                        } else {
                                            expandedSessionId = session.id
                                            if chatMessages[session.id] == nil {
                                                let result = store.loadChatMessages(for: session, limit: 8)
                                                chatMessages[session.id] = (result.messages, result.totalCount)
                                            }
                                        }
                                    }
                                }

                                if expandedSessionId == session.id,
                                   let cached = chatMessages[session.id],
                                   !cached.0.isEmpty {
                                    ChatPreviewView(messages: cached.0, totalCount: cached.1)
                                        .padding(.horizontal, Theme.itemH)
                                        .padding(.bottom, Spacing.s)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                }
                .frame(maxHeight: 440)
            }

            GradientSeparator()
            HStack {
                Text("\u{2195} Navigate  \u{2423} Preview  \u{23CE} Resume  \u{238B} Back")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
        }
    }

    private func resumeSession(_ session: Session) {
        TerminalLauncher.resume(sessionId: session.id, cwd: session.cwd, terminal: settings.terminal)
    }
}
