//
//  PinStore.swift
//  ResumeBar
//

import Foundation

@Observable class PinStore {
    private(set) var pinnedIds: [String] = []

    @ObservationIgnored private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ResumeBar")
        fileURL = dir.appendingPathComponent("pinned-sessions.json")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        load()
    }

    func isPinned(_ sessionId: String) -> Bool {
        pinnedIds.contains(sessionId)
    }

    func toggle(_ sessionId: String) {
        if isPinned(sessionId) {
            unpin(sessionId)
        } else {
            pin(sessionId)
        }
    }

    func pin(_ sessionId: String) {
        guard !isPinned(sessionId) else { return }
        pinnedIds.append(sessionId)
        save()
    }

    func unpin(_ sessionId: String) {
        pinnedIds.removeAll { $0 == sessionId }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        pinnedIds = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(pinnedIds) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
