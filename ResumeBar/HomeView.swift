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
    var onSelectSession: ((Session, Project, String?) -> Void)?

    @State private var searchResults: [SearchResult] = []
    @State private var isSearchingContent = false
    @State private var searchTask: Task<Void, Never>?

    @FocusState private var searchFocused: Bool

    private var filteredPinned: [(project: Project, session: Session)] {
        store.filteredPinnedSessions(pinStore: pinStore, query: store.searchText)
    }

    private var filteredRecent: [(project: Project, session: Session)] {
        store.filteredRecentSessions(limit: settings.recentSessionCount, query: store.searchText)
    }

    private var filteredProjects: [Project] {
        store.filteredProjects(query: store.searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            GradientSeparator()

            if store.totalSessions > 0 {
                HStack(spacing: 4) {
                    Text("\(store.totalSessions) sessions")
                    Text("·").foregroundStyle(Theme.accent.opacity(0.4))
                    Text("\(SessionStore.formatTokens(store.totalTokens)) tokens")
                    Text("·").foregroundStyle(Theme.accent.opacity(0.4))
                    Text("\(store.totalProjects) projects")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }

            if store.projects.isEmpty {
                emptyState(icon: "clock.badge.questionmark", text: "No sessions found")
            } else if filteredProjects.isEmpty && filteredPinned.isEmpty && filteredRecent.isEmpty && searchResults.isEmpty && !isSearchingContent {
                emptyState(icon: "magnifyingglass", text: "No matching sessions")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if store.isIndexing && store.searchText.count >= 3 {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Indexing sessions...")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.top, Spacing.m)
                            .padding(.leading, Spacing.xs)
                        }

                        if !searchResults.isEmpty {
                            sectionHeader("SEARCH RESULTS")
                            ForEach(searchResults) { result in
                                if let (project, session) = findSession(id: result.sessionId) {
                                    SessionRowView(
                                        session: session,
                                        projectName: project.displayName,
                                        displayTitle: store.displayTitle(for: session),
                                        isPinned: pinStore.isPinned(session.id),
                                        isSelected: false,
                                        snippet: result.snippet,
                                        onSelect: { onSelectSession?(session, project, store.searchText) },
                                        onResume: { resumeSession(session) },
                                        onTogglePin: { pinStore.toggle(session.id) },
                                        onRename: { aliasStore.set($0, for: session.id) }
                                    )
                                }
                            }
                        }

                        if !filteredPinned.isEmpty && searchResults.isEmpty {
                            sectionHeader("PINNED")
                            ForEach(filteredPinned, id: \.session.id) { pair in
                                SessionRowView(
                                    session: pair.session,
                                    projectName: pair.project.displayName,
                                    displayTitle: store.displayTitle(for: pair.session),
                                    isPinned: true,
                                    isSelected: false,
                                    onSelect: { onSelectSession?(pair.session, pair.project, nil) },
                                    onResume: { resumeSession(pair.session) },
                                    onTogglePin: { pinStore.toggle(pair.session.id) },
                                    onRename: { aliasStore.set($0, for: pair.session.id) }
                                )
                            }
                        }

                        if !filteredRecent.isEmpty && searchResults.isEmpty {
                            sectionHeader("RECENT")
                            ForEach(filteredRecent, id: \.session.id) { pair in
                                SessionRowView(
                                    session: pair.session,
                                    projectName: pair.project.displayName,
                                    displayTitle: store.displayTitle(for: pair.session),
                                    isPinned: pinStore.isPinned(pair.session.id),
                                    isSelected: false,
                                    onSelect: { onSelectSession?(pair.session, pair.project, nil) },
                                    onResume: { resumeSession(pair.session) },
                                    onTogglePin: { pinStore.toggle(pair.session.id) },
                                    onRename: { aliasStore.set($0, for: pair.session.id) }
                                )
                            }
                        }

                        if !filteredProjects.isEmpty && searchResults.isEmpty {
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
        .onChange(of: store.searchText) { _, newValue in
            searchTask?.cancel()
            if newValue.count < 3 {
                searchResults = []
                isSearchingContent = false
                return
            }
            isSearchingContent = true
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                let results = store.searchContent(query: newValue)
                guard !Task.isCancelled else { return }
                searchResults = results
                isSearchingContent = false
            }
        }
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
            .contentShape(Rectangle())
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

    // MARK: - Helpers

    private func findSession(id: String) -> (Project, Session)? {
        for project in store.projects {
            if let session = project.sessions.first(where: { $0.id == id }) {
                return (project, session)
            }
        }
        return nil
    }

    // MARK: - Actions

    private func resumeSession(_ session: Session) {
        TerminalLauncher.resume(sessionId: session.id, cwd: session.cwd, terminal: settings.terminal)
    }
}
