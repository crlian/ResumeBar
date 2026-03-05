//
//  AliasStore.swift
//  ResumeBar
//

import Combine
import Foundation

class AliasStore: ObservableObject {
    @Published private(set) var aliases: [String: String] = [:]

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ResumeBar")
        fileURL = dir.appendingPathComponent("session-aliases.json")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        load()
    }

    func alias(for sessionId: String) -> String? {
        aliases[sessionId]
    }

    func set(_ name: String, for sessionId: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            aliases.removeValue(forKey: sessionId)
        } else {
            aliases[sessionId] = trimmed
        }
        save()
    }

    func remove(for sessionId: String) {
        aliases.removeValue(forKey: sessionId)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return }
        aliases = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(aliases) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
