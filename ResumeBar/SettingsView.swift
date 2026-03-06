//
//  SettingsView.swift
//  ResumeBar
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case display = "Display"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "gearshape.fill"
        case .display: "eye.fill"
        case .about: "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SettingsTabButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.s)

            Divider()
                .overlay(Theme.border)

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case .general:
                        GeneralTab(settings: settings)
                    case .display:
                        DisplayTab(settings: settings)
                    case .about:
                        AboutTab()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            }
        }
        .frame(width: 420, height: 380)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Tab Button

private struct SettingsTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Theme.accent : .secondary)
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.accent : .secondary)
            }
            .frame(width: 72, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Theme.accent.opacity(0.12) : (isHovered ? Color.white.opacity(0.04) : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Theme.accent.opacity(0.25) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.bottom, 10)
    }
}

// MARK: - Section Divider

private struct SectionDivider: View {
    var body: some View {
        Divider()
            .overlay(Theme.border)
            .padding(.vertical, 16)
    }
}

// MARK: - Setting Row

private struct SettingRow<Content: View>: View {
    let title: String
    let description: String?
    @ViewBuilder let control: () -> Content

    init(_ title: String, description: String? = nil, @ViewBuilder control: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.control = control
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                if let description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            control()
        }
        .padding(.bottom, 6)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SectionHeader(title: "Terminal")

        SettingRow("Default terminal", description: "Which terminal to launch Claude sessions in.") {
            VStack(alignment: .trailing, spacing: 4) {
                Picker("", selection: $settings.terminal) {
                    ForEach(SupportedTerminal.allCases) { terminal in
                        Text(terminal.displayName).tag(terminal)
                    }
                }
                .labelsHidden()
                .frame(width: 160)

                if settings.terminal == .warp {
                    Text("Warp can't run commands directly — the resume command will be copied to your clipboard.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 220, alignment: .trailing)
                }
            }
        }

        SectionDivider()

        SectionHeader(title: "Automation")

        SettingRow("Refresh cadence", description: "How often ResumeBar scans for new sessions in the background.") {
            Picker("", selection: $settings.autoRefreshInterval) {
                Text("Off").tag(0)
                Text("30s").tag(30)
                Text("1 min").tag(60)
                Text("5 min").tag(300)
            }
            .labelsHidden()
            .frame(width: 100)
        }
    }
}

// MARK: - Display Tab

private struct DisplayTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SectionHeader(title: "Home Screen")

        SettingRow("Recent sessions", description: "Maximum number of recent sessions shown on the home screen.") {
            Stepper("\(settings.recentSessionCount)", value: $settings.recentSessionCount, in: 1...10)
                .frame(width: 100)
        }
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("ResumeBar")
                .font(.system(size: 18, weight: .semibold))

            Text("Browse and resume your Claude Code sessions\nfrom the menu bar.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("v1.0.0")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit ResumeBar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.accent)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
