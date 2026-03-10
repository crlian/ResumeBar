import AppKit
import SwiftUI

struct MenuBarIcon: View {
    var body: some View {
        Image(nsImage: buildIcon())
    }

    private func buildIcon() -> NSImage {
        // The mascot grid is 17 cols x 12 rows (rows 3-11 have content, shifted to 0-8)
        // We'll render into 18x18pt, centering the 11x9 active area
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { rect in
            let cellSize: CGFloat = 1.3
            // Active grid spans cols 2-14 (13 wide) and rows 3-11 (9 tall)
            // Center: offsetX = (18 - 13*1.3)/2 = 0.55, offsetY = (18 - 9*1.3)/2 = 3.15
            let offsetX: CGFloat = 0.55
            let offsetY: CGFloat = 3.15

            func fill(_ col: Int, _ row: Int) {
                let x = offsetX + CGFloat(col - 2) * cellSize
                let y = offsetY + CGFloat(row - 3) * cellSize
                NSBezierPath(rect: NSRect(x: x, y: y, width: cellSize, height: cellSize)).fill()
            }

            // Body color (template image uses black, macOS tints it)
            NSColor.black.setFill()

            // Row 3: ears - cols 5,6,10,11
            for c in [5, 6, 10, 11] { fill(c, 3) }

            // Row 4: top of head - cols 4-12
            for c in 4...12 { fill(c, 4) }

            // Row 5: head - cols 3-13
            for c in 3...13 { fill(c, 5) }

            // Row 6: face with eye gaps - body cols 3,4,7,8,9,12,13 + eyes 5,6,10,11
            for c in [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] { fill(c, 6) }

            // Row 7: body + arms - cols 2-14
            for c in 2...14 { fill(c, 7) }

            // Row 8: body + arms - cols 2-14
            for c in 2...14 { fill(c, 8) }

            // Row 9: narrower body + arm tips - cols 2,3, 4-12, 13,14
            for c in [2, 3] { fill(c, 9) }
            for c in 4...12 { fill(c, 9) }
            for c in [13, 14] { fill(c, 9) }

            // Row 10: legs + arm feet - cols 2,3, 5,6,10,11, 13,14
            for c in [2, 3, 5, 6, 10, 11, 13, 14] { fill(c, 10) }

            // Row 11: legs - cols 5,6,10,11
            for c in [5, 6, 10, 11] { fill(c, 11) }

            // Now cut out the eyes (draw background color over them)
            // Since isTemplate=true, we use clear color to "erase" the eyes
            NSColor.clear.setFill()
            NSGraphicsContext.current?.compositingOperation = .copy
            for c in [5, 6, 10, 11] { fill(c, 6) }

            return true
        }
        image.isTemplate = true
        return image
    }
}
