//
//  SearchIndex.swift
//  ResumeBar

import Foundation
import SQLite3

struct SearchResult: Identifiable {
    let id = UUID()
    let sessionId: String
    let project: String
    let role: String
    let snippet: String
    let rank: Double
}

final class SearchIndex {
    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ResumeBar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        dbPath = dir.appendingPathComponent("search.db").path
    }

    func open() {
        guard db == nil else { return }
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("[SearchIndex] Failed to open database: \(String(cString: sqlite3_errmsg(db!)))")
            db = nil
            return
        }
        createTablesIfNeeded()
    }

    func close() {
        if let db {
            sqlite3_close(db)
        }
        db = nil
    }

    private func createTablesIfNeeded() {
        guard let db else { return }
        let sql = """
        CREATE TABLE IF NOT EXISTS indexed_sessions (
            session_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            last_modified REAL NOT NULL
        );
        CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
            session_id UNINDEXED,
            role,
            content,
            project,
            tokenize='porter unicode61'
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    // MARK: - Indexing

    func needsReindex(sessionId: String, lastModified: Date) -> Bool {
        guard let db else { return true }
        let sql = "SELECT last_modified FROM indexed_sessions WHERE session_id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return true }
        sqlite3_bind_text(stmt, 1, sessionId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) == SQLITE_ROW {
            let stored = sqlite3_column_double(stmt, 0)
            return abs(stored - lastModified.timeIntervalSince1970) > 1.0
        }
        return true
    }

    func indexSession(sessionId: String, project: String, messages: [(role: String, content: String)], lastModified: Date) {
        guard let db else { return }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        // Remove old entries
        removeSession(sessionId: sessionId)

        // Insert messages into FTS
        let insertSQL = "INSERT INTO messages_fts (session_id, role, content, project) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else { return }

        for msg in messages {
            sqlite3_bind_text(stmt, 1, sessionId, -1, transient)
            sqlite3_bind_text(stmt, 2, msg.role, -1, transient)
            sqlite3_bind_text(stmt, 3, msg.content, -1, transient)
            sqlite3_bind_text(stmt, 4, project, -1, transient)
            sqlite3_step(stmt)
            sqlite3_reset(stmt)
        }
        sqlite3_finalize(stmt)

        // Update indexed_sessions tracker
        let upsertSQL = "INSERT OR REPLACE INTO indexed_sessions (session_id, file_path, last_modified) VALUES (?, ?, ?);"
        var uStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, upsertSQL, -1, &uStmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(uStmt, 1, sessionId, -1, transient)
        sqlite3_bind_text(uStmt, 2, "", -1, transient)
        sqlite3_bind_double(uStmt, 3, lastModified.timeIntervalSince1970)
        sqlite3_step(uStmt)
        sqlite3_finalize(uStmt)
    }

    func removeSession(sessionId: String) {
        guard let db else { return }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        let delFTS = "DELETE FROM messages_fts WHERE session_id = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, delFTS, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, sessionId, -1, transient)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)

        let delTracker = "DELETE FROM indexed_sessions WHERE session_id = ?;"
        var stmt2: OpaquePointer?
        if sqlite3_prepare_v2(db, delTracker, -1, &stmt2, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt2, 1, sessionId, -1, transient)
            sqlite3_step(stmt2)
        }
        sqlite3_finalize(stmt2)
    }

    func pruneDeletedSessions(existingIds: Set<String>) {
        guard let db else { return }
        let sql = "SELECT session_id FROM indexed_sessions;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }

        var toRemove: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cStr = sqlite3_column_text(stmt, 0) {
                let id = String(cString: cStr)
                if !existingIds.contains(id) {
                    toRemove.append(id)
                }
            }
        }

        for id in toRemove {
            removeSession(sessionId: id)
        }
    }

    // MARK: - Search

    func search(query: String, limit: Int = 20) -> [SearchResult] {
        guard let db else { return [] }
        let sanitized = sanitizeQuery(query)
        guard !sanitized.isEmpty else { return [] }

        let sql = """
        SELECT session_id, project, role,
               snippet(messages_fts, 2, '[', ']', '...', 40) as snippet,
               rank
        FROM messages_fts
        WHERE messages_fts MATCH ?
        ORDER BY rank
        LIMIT ?;
        """

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, sanitized, -1, transient)
        sqlite3_bind_int(stmt, 2, Int32(limit))

        var results: [SearchResult] = []
        // Deduplicate by sessionId — keep only best-ranked result per session
        var seenSessions: Set<String> = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let sessionId = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
            if seenSessions.contains(sessionId) { continue }
            seenSessions.insert(sessionId)

            let project = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
            let role = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
            let snippet = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
            let rank = sqlite3_column_double(stmt, 4)

            results.append(SearchResult(
                sessionId: sessionId,
                project: project,
                role: role,
                snippet: snippet,
                rank: rank
            ))
        }
        return results
    }

    private func sanitizeQuery(_ query: String) -> String {
        // Remove FTS5 special characters, then wrap tokens in quotes
        var cleaned = query
        for ch in ["\"", "*", "(", ")", ":", "^", "{", "}", "~", "-"] {
            cleaned = cleaned.replacingOccurrences(of: ch, with: " ")
        }
        let tokens = cleaned.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return "" }
        if tokens.count == 1 { return "\"\(tokens[0])\"" }
        return tokens.map { "\"\($0)\"" }.joined(separator: " ")
    }
}
