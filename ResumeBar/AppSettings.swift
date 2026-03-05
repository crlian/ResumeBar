//
//  AppSettings.swift
//  ResumeBar
//

import Combine
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("terminal") var terminal: String = "Terminal" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("maxSessionsPerProject") var maxSessionsPerProject: Int = 3 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("autoRefreshInterval") var autoRefreshInterval: Int = 0 {
        didSet { objectWillChange.send() }
    }
}
