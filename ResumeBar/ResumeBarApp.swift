//
//  ResumeBarApp.swift
//  ResumeBar
//
//  Created by Cesar Rico Otero on 4/03/26.
//

import SwiftUI

@main
struct ResumeBarApp: App {
    @State private var aliasStore = AliasStore()
    @State private var settings = AppSettings()
    @State private var pinStore = PinStore()
    @State private var store: SessionStore

    init() {
        let alias = AliasStore()
        _aliasStore = State(initialValue: alias)
        _store = State(initialValue: SessionStore(aliasStore: alias))
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(store: store, settings: settings, aliasStore: aliasStore, pinStore: pinStore)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings)
        }
    }
}
