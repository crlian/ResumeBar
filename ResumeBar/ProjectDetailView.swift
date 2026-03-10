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
    var onSelectSession: (Session) -> Void

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
                        .frame(width: 10, height: 10)
                    Text(project.displayName)
                        .font(Theme.projectName)
                    Spacer()
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Theme.itemH)
                .padding(.vertical, Spacing.m)
            }
            .buttonStyle(.plain)

            Divider()

            if project.totalTokens > 0 {
                HStack(spacing: 4) {
                    Text("\(project.sessions.count) sessions")
                    Text("·").foregroundStyle(Theme.textTertiary)
                    Text("\(SessionStore.formatTokens(project.totalTokens)) tokens")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }

            if sessions.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                    Text("No matching sessions")
                        .font(Theme.caption)
                }
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.l)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sessions) { session in
                            SessionRowView(
                                session: session,
                                projectName: nil,
                                displayTitle: store.displayTitle(for: session),
                                isPinned: pinStore.isPinned(session.id),
                                isSelected: false,
                                onSelect: { onSelectSession(session) },
                                onResume: { resumeSession(session) },
                                onTogglePin: { pinStore.toggle(session.id) },
                                onRename: { aliasStore.set($0, for: session.id) }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                }
                .frame(maxHeight: 440)
            }

            Divider()
            HStack {
                Text("\u{2195} Navigate  \u{2423} Preview  \u{23CE} Resume  \u{238B} Back")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
        }
    }

    private func resumeSession(_ session: Session) {
        TerminalLauncher.resume(sessionId: session.id, cwd: session.cwd, terminal: settings.terminal)
    }
}
