//
//  ProjectsListView.swift
//  ResumeBar
//

import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var store: SessionStore
    let onSelectProject: (Project) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar
            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.secondaryLabelColor))
                    .font(.system(size: 12))
                TextField("Search projects...", text: $store.projectSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, Spacing.s)
            .frame(height: Spacing.xxxl)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.s)

            GradientSeparator()
                .padding(.horizontal, Spacing.l)

            if store.filteredProjects.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: Spacing.s) {
                        ForEach(store.filteredProjects) { project in
                            projectCard(project)
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
            if !store.projectSearchText.isEmpty {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundColor(Color(.quaternaryLabelColor))
                Text("No matching projects")
                    .foregroundColor(Color(.secondaryLabelColor))
                    .font(Theme.caption())
            } else {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 32))
                    .foregroundColor(Color(.quaternaryLabelColor))
                Text("No projects found")
                    .foregroundColor(Color(.secondaryLabelColor))
                    .font(Theme.caption())
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func projectCard(_ project: Project) -> some View {
        Button {
            onSelectProject(project)
        } label: {
            HStack(spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.displayName)
                        .font(Theme.title())
                        .foregroundColor(Color(.labelColor))
                        .lineLimit(1)

                    HStack(spacing: Spacing.s) {
                        Text("\(project.sessions.count) session\(project.sessions.count == 1 ? "" : "s")")
                            .font(Theme.caption())
                            .foregroundColor(Color(.secondaryLabelColor))

                        Text("·")
                            .foregroundColor(Color(.tertiaryLabelColor))

                        Text(store.relativeDate(project.lastActivity))
                            .font(Theme.caption())
                            .foregroundColor(Color(.tertiaryLabelColor))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabelColor))
            }
            .padding(Spacing.m)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .cardStyle()
        .hoverEffect()
    }
}
