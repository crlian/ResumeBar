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

    static func == (lhs: NavigationScreen, rhs: NavigationScreen) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home): return true
        case (.projectDetail(let a), .projectDetail(let b)): return a.id == b.id
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
                        withAnimation(.easeOut(duration: 0.15)) {
                            screen = .projectDetail(project)
                        }
                    }
                )
                .transition(.move(edge: .leading))

            case .projectDetail(let project):
                ProjectDetailView(
                    project: project,
                    store: store,
                    pinStore: pinStore,
                    aliasStore: aliasStore,
                    settings: settings,
                    onBack: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            screen = .home
                        }
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .frame(width: 380)
        .preferredColorScheme(.dark)
        .onKeyPress(.escape) {
            if screen != .home {
                withAnimation(.easeOut(duration: 0.15)) {
                    screen = .home
                }
                return .handled
            }
            NSApp.keyWindow?.close()
            return .handled
        }
    }
}
