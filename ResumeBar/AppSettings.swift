//
//  AppSettings.swift
//  ResumeBar
//

import SwiftUI

@Observable class AppSettings {
    @ObservationIgnored @AppStorage("terminal") var terminal: String = "Terminal"
    @ObservationIgnored @AppStorage("autoRefreshInterval") var autoRefreshInterval: Int = 0
    @ObservationIgnored @AppStorage("recentSessionCount") var recentSessionCount: Int = 5
}
