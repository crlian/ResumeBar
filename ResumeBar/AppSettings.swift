//
//  AppSettings.swift
//  ResumeBar
//

import Foundation

@Observable class AppSettings {
    var terminal: SupportedTerminal {
        didSet { UserDefaults.standard.set(terminal.rawValue, forKey: "terminal") }
    }
    var autoRefreshInterval: Int {
        didSet { UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval") }
    }
    var recentSessionCount: Int {
        didSet { UserDefaults.standard.set(recentSessionCount, forKey: "recentSessionCount") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "terminal") ?? ""
        terminal = SupportedTerminal(rawValue: raw) ?? .terminal
        autoRefreshInterval = UserDefaults.standard.integer(forKey: "autoRefreshInterval")
        recentSessionCount = (UserDefaults.standard.object(forKey: "recentSessionCount") as? Int) ?? 5
    }
}
