//
//  ResumeBarApp.swift
//  ResumeBar
//
//  Created by Cesar Rico Otero on 4/03/26.
//

import SwiftUI

@main
struct ResumeBarApp: App {
    @StateObject private var aliasStore = AliasStore()
    @StateObject private var settings = AppSettings()
    @StateObject private var pinStore = PinStore()

    @StateObject private var store: SessionStore

    init() {
        let alias = AliasStore()
        _aliasStore = StateObject(wrappedValue: alias)
        _settings = StateObject(wrappedValue: AppSettings())
        _store = StateObject(wrappedValue: SessionStore(aliasStore: alias))
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
