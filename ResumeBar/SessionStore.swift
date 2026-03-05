//
//  SessionStore.swift
//  ResumeBar
//

import Combine
import Foundation

class SessionStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var projectSearchText: String = ""
    @Published var sessionSearchText: String = ""

    private let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private var fileWatcherSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var chatPreviewCache: [String: ([ChatMessage], Int)] = [:]

    var filteredProjects: [Project] {
        if projectSearchText.isEmpty {
            return projects
        }
        let query = projectSearchText.lowercased()
        return projects.filter {
            $0.displayName.lowercased().contains(query)
        }
    }

    func filteredSessions(for projectId: String) -> [Session] {
        guard let project = projects.first(where: { $0.id == projectId }) else {
            return []
        }
        if sessionSearchText.isEmpty {
            return project.sessions
        }
        let query = sessionSearchText.lowercased()
        return project.sessions.filter {
            $0.title.lowercased().contains(query)
        }
    }

    func loadChatMessages(for session: Session, limit: Int = 8) -> (messages: [ChatMessage], totalCount: Int) {
        if let cached = chatPreviewCache[session.id] {
            return cached
        }

        guard let data = try? Data(contentsOf: session.jsonlURL) else {
            return ([], 0)
        }
        let content = String(decoding: data, as: UTF8.self)
        let lines = content.components(separatedBy: .newlines)

        let ignoredTypes: Set<String> = ["tool_use", "tool_result", "thinking", "progress", "file-history-snapshot"]
        var allMessages: [ChatMessage] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let type = json["type"] as? String
            else { continue }

            if ignoredTypes.contains(type) { continue }

            if type == "user", let message = json["message"] as? [String: Any] {
                if let text = extractText(from: message), !text.isEmpty {
                    allMessages.append(ChatMessage(role: .user, text: text))
                }
            } else if type == "assistant", let message = json["message"] as? [String: Any] {
                if let text = extractText(from: message), !text.isEmpty {
                    allMessages.append(ChatMessage(role: .assistant, text: text))
                }
            }
        }

        let total = allMessages.count
        let limited = Array(allMessages.prefix(limit))
        let result = (limited, total)
        chatPreviewCache[session.id] = result
        return result
    }

    private func extractText(from message: [String: Any]) -> String? {
        if let text = message["content"] as? String {
            return text
        }
        if let parts = message["content"] as? [[String: Any]] {
            let texts = parts.compactMap { part -> String? in
                guard part["type"] as? String == "text" else { return nil }
                return part["text"] as? String
            }
            let joined = texts.joined(separator: "\n")
            return joined.isEmpty ? nil : joined
        }
        return nil
    }

    init() {
        load()
        startFileWatcher()
    }

    deinit {
        fileWatcherSource?.cancel()
        if fileDescriptor >= 0 {
            close(fileDescriptor)
        }
    }

    private func startFileWatcher() {
        let fm = FileManager.default
        let projectsDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")

        fileDescriptor = open(projectsDir.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.load()
            }
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        source.resume()
        fileWatcherSource = source
    }

    func load() {
        chatPreviewCache = [:]

        let fm = FileManager.default
        let projectsDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")

        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            projects = []
            return
        }

        var result: [Project] = []

        for dir in projectDirs {
            guard (try? dir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
                continue
            }

            let dirName = dir.lastPathComponent
            let displayName = dirName.split(separator: "-").last.map(String.init) ?? dirName

            guard let files = try? fm.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ) else { continue }

            var sessions: [Session] = []

            for file in files where file.pathExtension == "jsonl" {
                guard let session = parseSession(at: file, projectPath: dirName) else { continue }
                sessions.append(session)
            }

            guard !sessions.isEmpty else { continue }
            sessions.sort { $0.lastActivity > $1.lastActivity }

            let projectLastActivity = sessions.first?.lastActivity ?? .distantPast

            result.append(Project(
                id: dirName,
                path: dirName,
                displayName: displayName,
                sessions: sessions,
                lastActivity: projectLastActivity
            ))
        }

        result.sort { $0.lastActivity > $1.lastActivity }
        projects = result
    }

    private func parseSession(at url: URL, projectPath: String) -> Session? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let content = String(decoding: data, as: UTF8.self)
        let lines = content.components(separatedBy: .newlines)

        let sessionId = url.deletingPathExtension().lastPathComponent

        let fm = FileManager.default
        let lastActivity = (try? fm.attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? Date()

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  json["type"] as? String == "user",
                  let message = json["message"] as? [String: Any]
            else { continue }

            let title = extractText(from: message)
            guard let title, !title.isEmpty else { continue }

            var timestamp = lastActivity
            if let ts = json["timestamp"] as? String {
                timestamp = iso8601.date(from: ts) ?? lastActivity
            }

            let cwd = json["cwd"] as? String ?? ""

            return Session(
                id: sessionId,
                title: title,
                timestamp: timestamp,
                lastActivity: lastActivity,
                projectPath: projectPath,
                cwd: cwd,
                jsonlURL: url
            )
        }

        return nil
    }

    func relativeDate(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        if days < 7 { return "\(days)d" }
        let weeks = days / 7
        if weeks < 4 { return "\(weeks)w" }
        let months = days / 30
        if months < 12 { return "\(months)mo" }
        let years = days / 365
        return "\(years)y"
    }
}
