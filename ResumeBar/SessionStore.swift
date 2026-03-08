//
//  SessionStore.swift
//  ResumeBar

import Foundation

@Observable class SessionStore {
    var projects: [Project] = []
    var searchText: String = ""
    var hasMore: Bool = false

    let aliasStore: AliasStore

    func displayTitle(for session: Session) -> String {
        aliasStore.alias(for: session.id) ?? session.title
    }

    @ObservationIgnored private var sessionLoadLimit: Int = 50

    @ObservationIgnored private let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    @ObservationIgnored private var fileWatcherSource: DispatchSourceFileSystemObject?
    @ObservationIgnored private var fileDescriptor: Int32 = -1
    @ObservationIgnored private var chatPreviewCache: [String: ([ChatMessage], Int)] = [:]
    @ObservationIgnored private var debounceWork: DispatchWorkItem?

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

    func recentSessions(limit: Int) -> [(project: Project, session: Session)] {
        var all: [(Project, Session)] = []
        for project in projects {
            for session in project.sessions {
                all.append((project, session))
            }
        }
        all.sort { $0.1.lastActivity > $1.1.lastActivity }
        return Array(all.prefix(limit))
    }

    func filteredRecentSessions(limit: Int, query: String) -> [(project: Project, session: Session)] {
        let recent = recentSessions(limit: limit)
        let q = query.lowercased()
        if q.isEmpty { return recent }
        return recent.filter {
            displayTitle(for: $0.session).lowercased().contains(q)
                || $0.session.title.lowercased().contains(q)
                || $0.project.displayName.lowercased().contains(q)
        }
    }

    func filteredPinnedSessions(pinStore: PinStore, query: String) -> [(project: Project, session: Session)] {
        let pinned = pinnedSessions(pinStore: pinStore)
        let q = query.lowercased()
        if q.isEmpty { return pinned }
        return pinned.filter {
            displayTitle(for: $0.session).lowercased().contains(q)
                || $0.session.title.lowercased().contains(q)
                || $0.project.displayName.lowercased().contains(q)
        }
    }

    func filteredProjects(query: String) -> [Project] {
        let q = query.lowercased()
        if q.isEmpty { return projects }
        return projects.filter { project in
            project.displayName.lowercased().contains(q)
                || project.sessions.contains { session in
                    displayTitle(for: session).lowercased().contains(q)
                        || session.title.lowercased().contains(q)
                }
        }
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

    func loadAllChatMessages(for session: Session, maxMessages: Int = 200) -> [ChatMessage] {
        parseChatMessages(from: session.jsonlURL, tailBytes: 512_000, maxMessages: maxMessages)
    }

    func loadChatMessages(for session: Session, limit: Int = 8) -> (messages: [ChatMessage], totalCount: Int) {
        if let cached = chatPreviewCache[session.id] {
            return cached
        }

        let allMessages = parseChatMessages(from: session.jsonlURL)
        let total = allMessages.count
        let limited = Array(allMessages.prefix(limit))
        let result = (limited, total)
        chatPreviewCache[session.id] = result
        return result
    }

    // MARK: - Unified Chat Parsing

    nonisolated private func parseChatMessages(from url: URL, tailBytes: Int? = nil, maxMessages: Int? = nil) -> [ChatMessage] {
        let data: Data
        if let tailBytes,
           let handle = try? FileHandle(forReadingFrom: url) {
            defer { try? handle.close() }
            let fileSize = handle.seekToEndOfFile()
            if fileSize > tailBytes {
                handle.seek(toFileOffset: fileSize - UInt64(tailBytes))
            } else {
                handle.seek(toFileOffset: 0)
            }
            data = handle.readDataToEndOfFile()
        } else {
            guard let d = try? Data(contentsOf: url) else { return [] }
            data = d
        }

        let content = String(decoding: data, as: UTF8.self)
        let lines = content.components(separatedBy: .newlines)

        let ignoredTypes: Set<String> = ["tool_use", "tool_result", "thinking", "progress", "file-history-snapshot"]
        var messages: [ChatMessage] = []

        for line in lines {
            guard let json = parseJSONLine(line),
                  let type = json["type"] as? String
            else { continue }

            if ignoredTypes.contains(type) { continue }

            if (type == "user" || type == "assistant"),
               let message = json["message"] as? [String: Any],
               let text = extractTextFromMessage(message), !text.isEmpty {
                let role: ChatMessage.Role = type == "user" ? .user : .assistant
                messages.append(ChatMessage(role: role, text: text))
            }
        }

        if let maxMessages, messages.count > maxMessages {
            return Array(messages.suffix(maxMessages))
        }
        return messages
    }

    // MARK: - JSON Line Parsing

    nonisolated private func parseJSONLine(_ line: String) -> [String: Any]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let dict = obj as? [String: Any],
              dict["type"] is String
        else { return nil }
        return dict
    }

    nonisolated private func extractTextFromMessage(_ message: [String: Any]) -> String? {
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
            self?.debounceWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.load()
            }
            self?.debounceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
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
        Task.detached { [weak self] in
            guard let self else { return }
            let result = self.performLoad()
            await MainActor.run {
                self.projects = result.projects
                self.hasMore = result.hasMore
                self.chatPreviewCache = [:]
            }
        }
    }

    nonisolated private func performLoad() -> (projects: [Project], hasMore: Bool) {
        let fm = FileManager.default
        let projectsDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")

        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return ([], false)
        }

        var allFiles: [(url: URL, modDate: Date, projectDir: String)] = []

        for dir in projectDirs {
            guard (try? dir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
                continue
            }

            let dirName = dir.lastPathComponent

            guard let files = try? fm.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" {
                let modDate = (try? fm.attributesOfItem(atPath: file.path)[.modificationDate] as? Date) ?? .distantPast
                allFiles.append((file, modDate, dirName))
            }
        }

        allFiles.sort { $0.modDate > $1.modDate }
        let hasMore = allFiles.count > sessionLoadLimit
        let filesToParse = allFiles.prefix(sessionLoadLimit)

        var projectSessions: [String: [Session]] = [:]

        for entry in filesToParse {
            guard let session = parseSessionSync(at: entry.url, projectPath: entry.projectDir) else { continue }
            projectSessions[entry.projectDir, default: []].append(session)
        }

        var result: [Project] = []
        for (dirName, var sessions) in projectSessions {
            sessions.sort { $0.lastActivity > $1.lastActivity }

            // Derive display name from cwd of first session
            let displayName: String
            if let firstCwd = sessions.first?.cwd, !firstCwd.isEmpty {
                displayName = URL(fileURLWithPath: firstCwd).lastPathComponent
            } else {
                displayName = dirName.split(separator: "-").last.map(String.init) ?? dirName
            }

            result.append(Project(
                id: dirName,
                path: dirName,
                displayName: displayName,
                sessions: sessions,
                lastActivity: sessions.first?.lastActivity ?? .distantPast
            ))
        }

        result.sort { $0.lastActivity > $1.lastActivity }
        return (result, hasMore)
    }

    func loadMore() {
        sessionLoadLimit += 50
        load()
    }

    nonisolated private func parseSessionSync(at url: URL, projectPath: String) -> Session? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let content = String(decoding: data, as: UTF8.self)
        let lines = content.components(separatedBy: .newlines)

        let sessionId = url.deletingPathExtension().lastPathComponent

        let fm = FileManager.default
        let lastActivity = (try? fm.attributesOfItem(atPath: url.path)[.modificationDate] as? Date) ?? Date()

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var sessionModel: String?
        var sessionTokens: Int?

        for line in lines {
            guard let json = parseJSONLine(line),
                  let type = json["type"] as? String
            else { continue }

            if type == "assistant", sessionModel == nil,
               let message = json["message"] as? [String: Any],
               let model = message["model"] as? String {
                sessionModel = model
            }

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

            let title = extractTextFromMessage(message)
            guard let title, !title.isEmpty else { continue }

            var timestamp = lastActivity
            if let ts = json["timestamp"] as? String {
                timestamp = iso.date(from: ts) ?? lastActivity
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
}

// MARK: - Shared Utility

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
