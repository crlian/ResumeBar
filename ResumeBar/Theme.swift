//
//  Theme.swift
//  ResumeBar
//

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
    // MARK: - Colors (Claude dark palette)

    static let background = Color(hex: "#121212")
    static let surface = Color(hex: "#1C1C1C")
    static let border = Color(hex: "#2A2A2A")

    static let textPrimary = Color(hex: "#EAEAEA")
    static let textSecondary = Color(hex: "#9CA3AF")

    static let accent = Color(hex: "#D77757")
    static let accentSubtle = accent.opacity(0.15)
    static let accentGlow = accent.opacity(0.40)

    static let hoverBg = Color(hex: "#1F1F1F")
    static let successDot = Color(hex: "#10B981")

    static let cardFill = Color.white.opacity(0.03)
    static let cardFillHover = Color.white.opacity(0.06)
    static let cardBorder = Color(hex: "#2A2A2A")
    static let cardBorderHover = Color.white.opacity(0.10)

    static let searchBg = Color.white.opacity(0.04)
    static let searchBorder = Color(hex: "#2A2A2A")
    static let chatPreviewBg = Color.white.opacity(0.02)

    // MARK: - Project Colors

    static let projectColors: [Color] = [
        Color(hex: "#8B5CF6"),
        Color(hex: "#10B981"),
        Color(hex: "#3B82F6"),
        Color(hex: "#F59E0B"),
        Color(hex: "#EC4899"),
        Color(hex: "#06B6D4"),
        Color(hex: "#84CC16"),
        Color(hex: "#D77757"),
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

    static func searchFont() -> Font {
        .system(size: 14, weight: .regular, design: .default)
    }

    static func projectName() -> Font {
        .system(size: 13, weight: .semibold, design: .default)
    }

    static func title() -> Font {
        .system(size: 13, weight: .medium, design: .default)
    }

    static func body() -> Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    static func preview() -> Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    static func caption() -> Font {
        .system(size: 11, weight: .regular, design: .default)
    }

    static func overline() -> Font {
        .system(size: 10, weight: .semibold, design: .default)
    }

    static func messageBody() -> Font {
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

struct GradientSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(height: 1)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func hoverEffect() -> some View {
        modifier(HoverModifier())
    }
}
