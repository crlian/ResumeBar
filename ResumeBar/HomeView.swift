//
//  HomeView.swift
//  ResumeBar
//

import SwiftUI

struct HomeView: View {
    @Bindable var store: SessionStore
    let pinStore: PinStore
    let aliasStore: AliasStore
    let settings: AppSettings

    var onSelectProject: (Project) -> Void
    var onSelectSession: ((Session, Project) -> Void)?

    @FocusState private var searchFocused: Bool

    private var pinnedSessions: [(project: Project, session: Session)] {
        store.pinnedSessions(pinStore: pinStore)
    }

    private var recentSessions: [(project: Project, session: Session)] {
        store.recentSessions(limit: settings.recentSessionCount)
    }

    private var filteredProjects: [Project] {
        let query = store.searchText.lowercased()
        if query.isEmpty { return store.projects }
        return store.projects.filter { project in
            project.displayName.lowercased().contains(query)
                || project.sessions.contains { session in
                    store.displayTitle(for: session).lowercased().contains(query)
                        || session.title.lowercased().contains(query)
                }
        }
    }

    private var filteredPinned: [(project: Project, session: Session)] {
        let query = store.searchText.lowercased()
        if query.isEmpty { return pinnedSessions }
        return pinnedSessions.filter {
            store.displayTitle(for: $0.session).lowercased().contains(query)
                || $0.session.title.lowercased().contains(query)
                || $0.project.displayName.lowercased().contains(query)
        }
    }

    private var filteredRecent: [(project: Project, session: Session)] {
        let query = store.searchText.lowercased()
        if query.isEmpty { return recentSessions }
        return recentSessions.filter {
            store.displayTitle(for: $0.session).lowercased().contains(query)
                || $0.session.title.lowercased().contains(query)
                || $0.project.displayName.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            GradientSeparator()

            if store.projects.isEmpty {
                emptyState(icon: "clock.badge.questionmark", text: "No sessions found")
            } else if filteredProjects.isEmpty && filteredPinned.isEmpty && filteredRecent.isEmpty {
                emptyState(icon: "magnifyingglass", text: "No matching sessions")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !filteredPinned.isEmpty {
                            sectionHeader("PINNED")
                            ForEach(filteredPinned, id: \.session.id) { pair in
                                SessionRowView(
                                    session: pair.session,
                                    projectName: pair.project.displayName,
                                    displayTitle: store.displayTitle(for: pair.session),
                                    isPinned: true,
                                    isSelected: false,
                                    onSelect: { onSelectSession?(pair.session, pair.project) },
                                    onResume: { resumeSession(pair.session) },
                                    onTogglePin: { pinStore.toggle(pair.session.id) },
                                    onDelete: { store.deleteSession(pair.session) },
                                    onRename: { aliasStore.set($0, for: pair.session.id) }
                                )
                            }
                        }

                        if !filteredRecent.isEmpty {
                            sectionHeader("RECENT")
                            ForEach(filteredRecent, id: \.session.id) { pair in
                                SessionRowView(
                                    session: pair.session,
                                    projectName: pair.project.displayName,
                                    displayTitle: store.displayTitle(for: pair.session),
                                    isPinned: pinStore.isPinned(pair.session.id),
                                    isSelected: false,
                                    onSelect: { onSelectSession?(pair.session, pair.project) },
                                    onResume: { resumeSession(pair.session) },
                                    onTogglePin: { pinStore.toggle(pair.session.id) },
                                    onDelete: { store.deleteSession(pair.session) },
                                    onRename: { aliasStore.set($0, for: pair.session.id) }
                                )
                            }
                        }

                        if !filteredProjects.isEmpty {
                            sectionHeader("PROJECTS")
                            ForEach(filteredProjects) { project in
                                projectRow(project)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                }
                .frame(maxHeight: 480)
            }

            GradientSeparator()
            keyboardHints
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)
                .font(.system(size: 13))
            TextField("Search sessions...", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(Theme.searchFont)
                .foregroundStyle(Theme.textPrimary)
                .focused($searchFocused)

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.itemH)
        .frame(height: Spacing.xxxl)
        .background(
            RoundedRectangle(cornerRadius: Theme.searchRadius, style: .continuous)
                .fill(Theme.searchBg)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.searchRadius, style: .continuous)
                        .stroke(Theme.searchBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.m)
        .padding(.bottom, Spacing.s)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.overline)
            .foregroundStyle(Theme.accent.opacity(0.7))
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.xs)
            .padding(.leading, Spacing.xs)
    }

    // MARK: - Project Row

    private func projectRow(_ project: Project) -> some View {
        Button {
            onSelectProject(project)
        } label: {
            HStack(spacing: Spacing.s) {
                Circle()
                    .fill(Theme.projectColor(for: project.displayName))
                    .frame(width: 10, height: 10)

                Text(project.displayName)
                    .font(Theme.projectName)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text("\(project.sessions.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.accent.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Theme.accentSubtle)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.itemH)
            .padding(.vertical, Theme.itemV)
            .hoverEffect()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
            Text(text)
                .foregroundStyle(Theme.textSecondary)
                .font(Theme.caption)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    // MARK: - Keyboard Hints

    private var keyboardHints: some View {
        HStack {
            Text("\u{2195} Navigate  \u{23CE} Open  \u{238B} Close")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Actions

    private func resumeSession(_ session: Session) {
        TerminalLauncher.resume(sessionId: session.id, cwd: session.cwd, terminal: settings.terminal)
    }
}
