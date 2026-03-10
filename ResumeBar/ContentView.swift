//
//  ContentView.swift
//  ResumeBar
//
//  Created by Cesar Rico Otero on 4/03/26.
//

import SwiftUI

enum NavigationScreen: Equatable {
    case home
    case projectDetail(Project)
    case sessionChat(Session, Project, searchQuery: String? = nil)

    static func == (lhs: NavigationScreen, rhs: NavigationScreen) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home): return true
        case (.projectDetail(let a), .projectDetail(let b)): return a.id == b.id
        case (.sessionChat(let a, _, _), .sessionChat(let b, _, _)): return a.id == b.id
        default: return false
        }
    }
}

struct ContentView: View {
    let store: SessionStore
    let settings: AppSettings
    let aliasStore: AliasStore
    let pinStore: PinStore

    @State private var screen: NavigationScreen = .home
    @State private var chatEnteredFromHome = false

    private let animation: Animation = .easeInOut(duration: 0.15)

    var body: some View {
        ZStack {
            switch screen {
            case .home:
                HomeView(
                    store: store,
                    pinStore: pinStore,
                    aliasStore: aliasStore,
                    settings: settings,
                    onSelectProject: { project in
                        withAnimation(animation) {
                            screen = .projectDetail(project)
                        }
                    },
                    onSelectSession: { session, project, searchQuery in
                        chatEnteredFromHome = true
                        withAnimation(animation) {
                            screen = .sessionChat(session, project, searchQuery: searchQuery)
                        }
                    }
                )
                .zIndex(0)
                .transition(.opacity)

            case .projectDetail(let project):
                ProjectDetailView(
                    project: project,
                    store: store,
                    pinStore: pinStore,
                    aliasStore: aliasStore,
                    settings: settings,
                    onBack: {
                        withAnimation(animation) {
                            screen = .home
                        }
                    },
                    onSelectSession: { session in
                        chatEnteredFromHome = false
                        withAnimation(animation) {
                            screen = .sessionChat(session, project)
                        }
                    }
                )
                .zIndex(1)
                .transition(.opacity)

            case .sessionChat(let session, let project, let searchQuery):
                ChatHistoryView(
                    session: session,
                    project: project,
                    store: store,
                    settings: settings,
                    searchQuery: searchQuery,
                    onBack: {
                        withAnimation(animation) {
                            screen = chatEnteredFromHome ? .home : .projectDetail(project)
                        }
                    }
                )
                .zIndex(2)
                .transition(.opacity)
            }
        }
        .clipped()
        .frame(width: 380)
        .preferredColorScheme(.dark)
        .onKeyPress(.escape) {
            switch screen {
            case .sessionChat(_, let project, _):
                withAnimation(animation) {
                    screen = chatEnteredFromHome ? .home : .projectDetail(project)
                }
                return .handled
            case .projectDetail:
                withAnimation(animation) {
                    screen = .home
                }
                return .handled
            case .home:
                NSApp.keyWindow?.close()
                return .handled
            }
        }
    }
}
