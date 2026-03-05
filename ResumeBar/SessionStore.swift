//
//  SessionStore.swift
//  ResumeBar
//

import Combine
import Foundation

class SessionStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var searchText: String = ""
    @Published var hasMore: Bool = false

    let aliasStore: AliasStore

    func displayTitle(for session: Session) -> String {
        aliasStore.alias(for: session.id) ?? session.title
    }

    private var sessionLoadLimit: Int = 50

    private let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private var fileWatcherSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var chatPreviewCache: [String: ([ChatMessage], Int)] = [:]

    // MARK: - Computed Properties

    var groupedFilteredSessions: [(project: Project, sessions: [Session])] {
        let query = searchText.lowercased()
        var results: [(project: Project, sessions: [Session])] = []

        for project in projects {
            if query.isEmpty {
                results.append((project, project.sessions))
            } else {
                let projectMatches = project.displayName.lowercased().contains(query)
                let matchingSessions = project.sessions.filter {
                    displayTitle(for: $0).lowercased().contains(query)
                        || $0.title.lowercased().contains(query)
                        || aliasStore.alias(for: $0.id)?.lowercased().contains(query) == true
                }
                if projectMatches {
                    results.append((project, project.sessions))
                } else if !matchingSessions.isEmpty {
                    results.append((project, matchingSessions))
                }
            }
        }

        return results
    }

    var recentSessions: [(project: Project, session: Session)] {
        var all: [(Project, Session)] = []
        for project in projects {
            for session in project.sessions {
                all.append((project, session))
            }
        }
        all.sort { $0.1.lastActivity > $1.1.lastActivity }
        return Array(all.prefix(5))
    }

    func pinnedSessions(pinStore: PinStore) -> [(project: Project, session: Session)] {
        var result: [(Project, Session)] = []
        for pinId in pinStore.pinnedIds {
            for project in projects {
                if let session = project.sessions.first(where: { $0.id == pinId }) {
                    result.append((project, session))
                    break
                }
            }
        }
        return result
    }

    var mostRecentSession: (project: Project, session: Session)? {
        var best: (Project, Session)?
        for project in projects {
            for session in project.sessions {
                if best == nil || session.lastActivity > best!.1.lastActivity {
                    best = (project, session)
                }
            }
        }
        return best
    }

    func isRecentlyActive(_ session: Session) -> Bool {
        -session.lastActivity.timeIntervalSinceNow < 3600
    }

    // MARK: - Chat Messages

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

    // MARK: - Delete

    func deleteSession(_ session: Session) {
        try? FileManager.default.removeItem(at: session.jsonlURL)
        load()
    }

    // MARK: - Init

    init(aliasStore: AliasStore) {
        self.aliasStore = aliasStore
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
            hasMore = false
            return
        }

        var allFiles: [(url: URL, modDate: Date, projectDir: String, displayName: String)] = []

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

            for file in files where file.pathExtension == "jsonl" {
                let modDate = (try? fm.attributesOfItem(atPath: file.path)[.modificationDate] as? Date) ?? .distantPast
                allFiles.append((file, modDate, dirName, displayName))
            }
        }

        allFiles.sort { $0.modDate > $1.modDate }
        hasMore = allFiles.count > sessionLoadLimit
        let filesToParse = allFiles.prefix(sessionLoadLimit)

        var projectSessions: [String: (displayName: String, sessions: [Session])] = [:]

        for entry in filesToParse {
            guard let session = parseSession(at: entry.url, projectPath: entry.projectDir) else { continue }
            var group = projectSessions[entry.projectDir] ?? (entry.displayName, [])
            group.sessions.append(session)
            projectSessions[entry.projectDir] = group
        }

        var result: [Project] = []
        for (dirName, group) in projectSessions {
            var sessions = group.sessions
            sessions.sort { $0.lastActivity > $1.lastActivity }
            result.append(Project(
                id: dirName,
                path: dirName,
                displayName: group.displayName,
                sessions: sessions,
                lastActivity: sessions.first?.lastActivity ?? .distantPast
            ))
        }

        result.sort { $0.lastActivity > $1.lastActivity }
        projects = result
    }

    func loadMore() {
        sessionLoadLimit += 50
        load()
    }

    private func parseSession(at url: URL, projectPath: String) -> Session? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let content = String(decoding: data, as: UTF8.self)
        let lines = content.components(separatedBy: .newlines)

        let sessionId = url.deletingPathExtension().lastPathComponent

        let fm = FileManager.default
        let lastActivity = (try? fm.attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? Date()

        var sessionModel: String?
        var sessionTokens: Int?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let type = json["type"] as? String
            else { continue }

            // Extract model from first assistant message
            if type == "assistant", sessionModel == nil,
               let message = json["message"] as? [String: Any],
               let model = message["model"] as? String {
                sessionModel = model
            }

            // Extract usage tokens
            if type == "assistant",
               let message = json["message"] as? [String: Any],
               let usage = message["usage"] as? [String: Any] {
                let input = usage["input_tokens"] as? Int ?? 0
                let output = usage["output_tokens"] as? Int ?? 0
                sessionTokens = (sessionTokens ?? 0) + input + output
            }

            guard type == "user",
                  let message = json["message"] as? [String: Any]
            else { continue }

            let title = extractText(from: message)
            guard let title, !title.isEmpty else { continue }

            var timestamp = lastActivity
            if let ts = json["timestamp"] as? String {
                timestamp = iso8601.date(from: ts) ?? lastActivity
            }

            let cwd = json["cwd"] as? String ?? ""
            let preview = String(title.prefix(80))

            return Session(
                id: sessionId,
                title: title,
                preview: preview,
                timestamp: timestamp,
                lastActivity: lastActivity,
                projectPath: projectPath,
                cwd: cwd,
                jsonlURL: url,
                model: sessionModel,
                totalTokens: sessionTokens
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
