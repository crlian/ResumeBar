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
                Text("··· \(totalCount - messages.count) more messages")
                    .font(Theme.caption())
                    .foregroundColor(Color(.tertiaryLabelColor))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.controlBackgroundColor).opacity(0.5))
        )
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            Text(message.text)
                .font(Theme.messageBody())
                .lineLimit(3)
                .foregroundColor(Color(.labelColor))
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.accent.opacity(0.12))
                )
        case .assistant:
            Text(message.text)
                .font(Theme.messageBody())
                .lineLimit(3)
                .foregroundColor(Color(.secondaryLabelColor))
                .padding(.vertical, Spacing.xs)
        }
    }
}
