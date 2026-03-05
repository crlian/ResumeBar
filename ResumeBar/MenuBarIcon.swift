import AppKit
import Combine
import SwiftUI

struct MenuBarIcon: View {
    @State private var cursorVisible = true

    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        Image(nsImage: buildIcon(cursorVisible: cursorVisible))
            .onReceive(timer) { _ in
                cursorVisible.toggle()
            }
    }

    private func buildIcon(cursorVisible: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let h = rect.height

            // Play triangle
            let playSize = h * 0.55
            let playX: CGFloat = 1
            let playY = (h - playSize) / 2
            let playPath = NSBezierPath()
            playPath.move(to: NSPoint(x: playX, y: playY))
            playPath.line(to: NSPoint(x: playX + playSize * 0.85, y: playY + playSize / 2))
            playPath.line(to: NSPoint(x: playX, y: playY + playSize))
            playPath.close()
            NSColor.black.setFill()
            playPath.fill()

            // Underscore cursor
            if cursorVisible {
                let cursorX = playX + playSize * 0.85 + 1
                let cursorY = h * 0.15
                let cursorWidth = h * 0.35
                let cursorHeight = h * 0.13
                let cursorRect = NSRect(x: cursorX, y: cursorY, width: cursorWidth, height: cursorHeight)
                NSBezierPath(rect: cursorRect).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
