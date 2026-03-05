//
//  SessionModel.swift
//  ResumeBar
//

import Foundation

struct Session: Identifiable {
    let id: String
    let title: String
    let timestamp: Date
    let lastActivity: Date
    let projectPath: String
    let cwd: String
    let jsonlURL: URL
}

struct Project: Identifiable {
    let id: String
    let path: String
    let displayName: String
    var sessions: [Session]
    let lastActivity: Date
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String

    enum Role {
        case user, assistant
    }
}
