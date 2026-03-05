//
//  Theme.swift
//  ResumeBar
//

import SwiftUI

enum Theme {
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.35)

    static func title() -> Font {
        .system(size: 14, weight: .semibold, design: .rounded)
    }

    static func caption() -> Font {
        .system(size: 11, weight: .regular, design: .rounded)
    }

    static func sectionHeader() -> Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }

    static func messageBody() -> Font {
        .system(size: 12, weight: .regular, design: .rounded)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            )
    }
}

struct HoverModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.1 : 0), radius: 8, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct GradientSeparator: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.accent.opacity(0.4), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
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
