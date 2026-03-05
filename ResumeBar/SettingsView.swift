//
//  SettingsView.swift
//  ResumeBar
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Picker("Terminal", selection: $settings.terminal) {
                Text("Terminal.app").tag("Terminal")
                Text("iTerm2").tag("iTerm2")
                Text("Ghostty").tag("Ghostty")
            }

            Stepper("Recent sessions: \(settings.recentSessionCount)",
                    value: $settings.recentSessionCount, in: 1...10)

            Picker("Auto-refresh", selection: $settings.autoRefreshInterval) {
                Text("Off").tag(0)
                Text("30s").tag(30)
                Text("1m").tag(60)
                Text("5m").tag(300)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 320)
    }
}
