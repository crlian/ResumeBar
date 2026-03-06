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
    case sessionChat(Session, Project)

    static func == (lhs: NavigationScreen, rhs: NavigationScreen) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home): return true
        case (.projectDetail(let a), .projectDetail(let b)): return a.id == b.id
        case (.sessionChat(let a, _), .sessionChat(let b, _)): return a.id == b.id
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
    @State private var navigatingForward = true
    @State private var chatEnteredFromHome = false

    private let animation: Animation = .spring(response: 0.25, dampingFraction: 0.95)

    private var viewTransition: AnyTransition {
        if navigatingForward {
            .asymmetric(insertion: .move(edge: .trailing), removal: .identity)
        } else {
            .asymmetric(insertion: .identity, removal: .move(edge: .trailing))
        }
    }

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
                            navigatingForward = true
                            screen = .projectDetail(project)
                        }
                    },
                    onSelectSession: { session, project in
                        chatEnteredFromHome = true
                        withAnimation(animation) {
                            navigatingForward = true
                            screen = .sessionChat(session, project)
                        }
                    }
                )
                .zIndex(0)
                .transition(viewTransition)

            case .projectDetail(let project):
                ProjectDetailView(
                    project: project,
                    store: store,
                    pinStore: pinStore,
                    aliasStore: aliasStore,
                    settings: settings,
                    onBack: {
                        withAnimation(animation) {
                            navigatingForward = false
                            screen = .home
                        }
                    },
                    onSelectSession: { session in
                        chatEnteredFromHome = false
                        withAnimation(animation) {
                            navigatingForward = true
                            screen = .sessionChat(session, project)
                        }
                    }
                )
                .zIndex(1)
                .transition(viewTransition)

            case .sessionChat(let session, let project):
                ChatHistoryView(
                    session: session,
                    project: project,
                    store: store,
                    settings: settings,
                    onBack: {
                        withAnimation(animation) {
                            navigatingForward = false
                            screen = chatEnteredFromHome ? .home : .projectDetail(project)
                        }
                    }
                )
                .zIndex(2)
                .transition(viewTransition)
            }
        }
        .clipped()
        .frame(width: 380)
        .preferredColorScheme(.dark)
        .onKeyPress(.escape) {
            switch screen {
            case .sessionChat(_, let project):
                withAnimation(animation) {
                    navigatingForward = false
                    screen = chatEnteredFromHome ? .home : .projectDetail(project)
                }
                return .handled
            case .projectDetail:
                withAnimation(animation) {
                    navigatingForward = false
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
