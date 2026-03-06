//
//  ChatPreviewView.swift
//  ResumeBar
//

import SwiftUI

struct ChatPreviewView: View {
    let messages: [ChatMessage]
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(messages) { message in
                messageBubble(message)
            }

            if totalCount > messages.count {
                Text("\u{00B7}\u{00B7}\u{00B7} \(totalCount - messages.count) more messages")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.chatPreviewBg)
        )
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            Text(message.text)
                .font(Theme.messageBody)
                .lineLimit(3)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.accentSubtle)
                )
        case .assistant:
            Text(message.text)
                .font(Theme.messageBody)
                .lineLimit(3)
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, Spacing.xs)
        }
    }
}
