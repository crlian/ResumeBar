//
//  Theme.swift
//  ResumeBar
//

import MarkdownUI
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

enum Theme {
    // MARK: - Colors (semantic system colors)

    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let border = Color(nsColor: .separatorColor)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    static let textMuted = Color(nsColor: .quaternaryLabelColor)

    static let accent = Color(hex: "#D77757")
    static let accentSubtle = accent.opacity(0.15)
    static let accentGlow = accent.opacity(0.40)

    static let hoverBg = Color(nsColor: .selectedContentBackgroundColor).opacity(0.1)
    static let successDot = Color(hex: "#7A9E5C")

    static let cardFill = Color(nsColor: .controlBackgroundColor).opacity(0.5)
    static let cardFillHover = Color(nsColor: .controlBackgroundColor)
    static let cardBorder = Color(nsColor: .separatorColor)
    static let cardBorderHover = Color(nsColor: .separatorColor).opacity(0.5)

    static let searchBg = Color(nsColor: .textBackgroundColor).opacity(0.3)
    static let searchBorder = Color(nsColor: .separatorColor)
    static let chatPreviewBg = Color.white.opacity(0.02)

    // MARK: - Chat Bubble Colors

    static let userBubbleBg = Color(hex: "#3D2218")
    static let claudeBubbleBg = Color(hex: "#1A1D22")
    static let claudeBadge = Color(hex: "#9BAED6")

    // MARK: - Diff Colors

    static let diffAdded = Color(hex: "#7A9E5C")
    static let diffRemoved = Color(hex: "#C75050")

    // MARK: - Project Colors

    static let projectColors: [Color] = [
        Color(hex: "#D77757"), // coral (accent)
        Color(hex: "#C9A84C"), // dorado/ámbar
        Color(hex: "#7A9E5C"), // verde salvia
        Color(hex: "#5B9EA6"), // teal
        Color(hex: "#8B9DC3"), // azul grisáceo
        Color(hex: "#A67DB8"), // lavanda
        Color(hex: "#C47878"), // rosa polvoriento
        Color(hex: "#B5613F"), // terracota
    ]

    static func projectColor(for name: String) -> Color {
        // djb2 hash for stable color assignment
        var hash: UInt64 = 5381
        for char in name.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(char)
        }
        return projectColors[Int(hash % UInt64(projectColors.count))]
    }

    // MARK: - Typography

    static var searchFont: Font {
        .system(size: 14, weight: .regular, design: .default)
    }

    static var projectName: Font {
        .system(size: 13, weight: .semibold, design: .default)
    }

    static var title: Font {
        .system(size: 13, weight: .medium, design: .default)
    }

    nonisolated(unsafe) static var body: Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    static var preview: Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    static var caption: Font {
        .system(size: 11, weight: .regular, design: .default)
    }

    static var overline: Font {
        .system(size: 11, weight: .semibold, design: .default)
    }

    static var messageBody: Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Spacing Constants

    static let itemV: CGFloat = 10
    static let itemH: CGFloat = 14
    static let cardRadius: CGFloat = 8
    static let searchRadius: CGFloat = 10
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }
}

struct HoverModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(isHovered ? Theme.hoverBg : .clear)
            )
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func hoverEffect() -> some View {
        modifier(HoverModifier())
    }

    func markdownStyle(textColor: Color = Theme.textPrimary) -> some View {
        self
            .markdownTextStyle {
                FontSize(12)
                ForegroundColor(textColor)
            }
            .markdownBlockStyle(\.codeBlock) { configuration in
                configuration.label
                    .padding(Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.black.opacity(0.3))
                    )
            }
    }
}
