//
//  ContentView.swift
//  ResumeBar
//
//  Created by Cesar Rico Otero on 4/03/26.
//

import SwiftUI

enum NavigationScreen: Equatable {
    case projectsList
    case sessionsDetail(projectId: String)
}

struct ContentView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var settings: AppSettings

    @State private var currentScreen: NavigationScreen = .projectsList
    @State private var selectedProject: Project?
    @State private var slideFromTrailing = true

    private let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )

    private let reverseTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .trailing)
    )

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch currentScreen {
                case .projectsList:
                    ProjectsListView(store: store) { project in
                        navigateTo(project: project)
                    }
                    .transition(slideFromTrailing ? reverseTransition : transition)

                case .sessionsDetail:
                    if let project = selectedProject {
                        SessionsDetailView(
                            store: store,
                            settings: settings,
                            project: project,
                            onBack: { navigateBack() }
                        )
                        .transition(slideFromTrailing ? transition : reverseTransition)
                    }
                }
            }
            .clipped()
            .animation(.spring(response: 0.35, dampingFraction: 0.88), value: currentScreen)

            // Footer
            Divider()
            HStack(spacing: Spacing.m) {
                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabelColor))
                }
                Spacer()
                footerButton(icon: "arrow.clockwise") {
                    store.load()
                }
                footerButton(icon: "xmark.circle") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
        }
        .frame(width: 360)
    }

    private func navigateTo(project: Project) {
        store.sessionSearchText = ""
        selectedProject = project
        slideFromTrailing = true
        currentScreen = .sessionsDetail(projectId: project.id)
    }

    private func navigateBack() {
        store.sessionSearchText = ""
        slideFromTrailing = false
        currentScreen = .projectsList
    }

    @ViewBuilder
    private func footerButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabelColor))
        }
        .buttonStyle(.plain)
    }
}
