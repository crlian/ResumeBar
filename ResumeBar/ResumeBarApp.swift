//
//  ResumeBarApp.swift
//  ResumeBar
//
//  Created by Cesar Rico Otero on 4/03/26.
//

import SwiftUI

@main
struct ResumeBarApp: App {
    @StateObject private var store = SessionStore()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra {
            ContentView(store: store, settings: settings)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: settings)
        }
    }
}
