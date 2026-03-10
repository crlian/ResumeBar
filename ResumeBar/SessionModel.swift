//
//  SessionModel.swift
//  ResumeBar
//

import Foundation

struct Session: Identifiable {
    let id: String
    let title: String
    var preview: String
    let timestamp: Date
    let lastActivity: Date
    let projectPath: String
    let cwd: String
    let jsonlURL: URL
    var model: String?
    var totalTokens: Int?
    var fileChanges: [FileChange] = []
    var totalFilesChanged: Int { Set(fileChanges.map(\.filePath)).count }
}

struct Project: Identifiable {
    let id: String
    let path: String
    let displayName: String
    var sessions: [Session]
    let lastActivity: Date

    var totalTokens: Int {
        sessions.reduce(0) { $0 + ($1.totalTokens ?? 0) }
    }
}

struct FileChange: Identifiable {
    let id = UUID()
    let filePath: String
    let fileName: String
    var linesAdded: Int
    var linesRemoved: Int
    var lastOperation: String
    var totalChanges: Int { linesAdded + linesRemoved }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String

    enum Role {
        case user, assistant
    }
}
