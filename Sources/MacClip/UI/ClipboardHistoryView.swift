import SwiftUI
import AppKit

public struct ClipboardHistoryView: View {
    @ObservedObject var store = ClipboardHistoryStore.shared
    @ObservedObject var hotkeyManager = GlobalHotKeyManager.shared
    @ObservedObject var pasteManager = PasteManager.shared
    @ObservedObject var launchManager = LaunchAtLoginManager.shared

    @FocusState private var isSearchFocused: Bool

    public var onSelect: ((ClipboardItem) -> Void)?
    public var onClose: (() -> Void)?

    public init(onSelect: ((ClipboardItem) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Window Drag Grab Handle (Apple HIG standard)
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 48, height: 5)
                Spacer()
            }
            .frame(height: 18)
            .contentShape(Rectangle())
            .background(WindowDragArea())
            .help("Drag to move window anywhere on screen")

            // Glass Header: Search & Glass Action Buttons
            headerView
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 8)

            // Category Filter Pills (All, Pinned, Text, Images, Links)
            if !store.isSettingsOpen && store.previewItem == nil {
                categoryFilterBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            // Accessibility Notice (Liquid Amber Glass Banner)
            if !pasteManager.isAccessibilityGranted && !pasteManager.isBannerDismissed && !store.isSettingsOpen && store.previewItem == nil {
                accessibilityBanner
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            // Subtle Glass Separator
            glassDivider

            // Content Area
            if store.isSettingsOpen {
                settingsView
            } else if let preview = store.previewItem {
                quickLookView(item: preview)
            } else if store.filteredItems.isEmpty {
                emptyStateView
            } else {
                listView
            }

            // Subtle Glass Separator
            glassDivider

            // Glass Footer Bar
            footerView
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .frame(width: 456, height: 575)
        .background(
            ZStack {
                VisualEffectBackground()

                // Caustic Liquid Glass Lighting Layer (Refraction Glow)
                RadialGradient(
                    colors: [
                        Color.accentColor.opacity(0.14),
                        Color.indigo.opacity(0.04),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 380
                )

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.clear,
                        Color.black.opacity(0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            // Dual-layer specular glass rim
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.white.opacity(0.16),
                                Color.primary.opacity(0.04),
                                Color.white.opacity(0.24)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.15), lineWidth: 0.5)
            }
        )
        .shadow(color: Color.black.opacity(0.28), radius: 24, y: 12)
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: store.isSettingsOpen) { isOpen in
            if !isOpen && store.previewItem == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            }
        }
        .onChange(of: store.previewItem) { preview in
            if preview == nil && !store.isSettingsOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            }
        }
    }

    // MARK: - Glass Separator (Dual-Hairline Physical Etched Groove)
    private var glassDivider: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.16),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.8)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.22),
                            Color.black.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.8)
        }
    }

    // MARK: - Header (Search + Glass Buttons)
    private var headerView: some View {
        HStack(spacing: 8) {
            if store.isSettingsOpen {
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        store.isSettingsOpen = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text("Clips")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Preferences")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(7)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            } else if store.previewItem != nil {
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        store.closePreview()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text("List")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Quick Look")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        store.closePreview()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(7)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help("Close Preview (Space / Esc)")
            } else {
                // Search Pill (Apple Liquid Glass Field)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchFocused ? .accentColor : .secondary.opacity(0.75))
                        .font(.system(size: 13, weight: isSearchFocused ? .semibold : .medium))
                        .shadow(color: isSearchFocused ? Color.accentColor.opacity(0.4) : Color.clear, radius: 4)

                    TextField("Search clips, links, images...", text: $store.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .focused($isSearchFocused)
                        .onSubmit {
                            if !store.filteredItems.isEmpty && store.selectedIndex < store.filteredItems.count {
                                onSelect?(store.filteredItems[store.selectedIndex])
                            }
                        }

                    if !store.searchText.isEmpty {
                        Button(action: {
                            store.searchText = ""
                            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7.5)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(isSearchFocused ? Color.white.opacity(0.09) : Color.white.opacity(0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: isSearchFocused
                                    ? [Color.accentColor.opacity(0.65), Color.accentColor.opacity(0.3)]
                                    : [Color.white.opacity(0.24), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSearchFocused ? 1.2 : 0.8
                        )
                )
                .shadow(color: isSearchFocused ? Color.accentColor.opacity(0.18) : Color.clear, radius: 6, y: 1)

                // Settings Toggle Pebble
                Button(action: {
                    if store.isSettingsOpen && hotkeyManager.isRecording {
                        hotkeyManager.stopRecording(cancelled: true)
                    }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        store.isSettingsOpen.toggle()
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                }) {
                    Image(systemName: store.isSettingsOpen ? "slider.horizontal.3.fill" : "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(store.isSettingsOpen ? .accentColor : .secondary)
                        .padding(7.5)
                        .background(
                            Circle()
                                .fill(store.isSettingsOpen ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    store.isSettingsOpen ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.14),
                                    lineWidth: 0.8
                                )
                        )
                }
                .buttonStyle(.plain)
                .help("Preferences & Shortcuts")

                // Close Pebble
                Button(action: {
                    if hotkeyManager.isRecording {
                        hotkeyManager.stopRecording(cancelled: true)
                    }
                    onClose?()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(7.5)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }
        }
    }

    // MARK: - Category Filter Bar (Unified Liquid Glass Tray)
    private var categoryFilterBar: some View {
        HStack(spacing: 3) {
            ForEach(ClipboardHistoryStore.FilterCategory.allCases) { category in
                let isSelected = store.selectedCategory == category
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                        store.selectedCategory = category
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                }) {
                    HStack(spacing: 4.5) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : categoryIconColor(for: category))

                        Text(category.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))

                        let c = store.count(for: category)
                        if c > 0 {
                            Text("\(c)")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .padding(.horizontal, 4.5)
                                .padding(.vertical, 1)
                                .background(isSelected ? Color.white.opacity(0.3) : Color.primary.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.8
                                            )
                                    )
                                    .shadow(color: Color.accentColor.opacity(0.35), radius: 4, y: 1.5)
                            } else {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.001))
                            }
                        }
                    )
                    .foregroundColor(isSelected ? .white : .primary.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.black.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func categoryIconColor(for cat: ClipboardHistoryStore.FilterCategory) -> Color {
        switch cat {
        case .all: return .primary.opacity(0.7)
        case .pinned: return .orange
        case .text: return .secondary
        case .images: return .indigo
        case .links: return .blue
        }
    }

    // MARK: - Accessibility Banner (Liquid Amber Glass)
    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(.orange)
                .font(.system(size: 12))
                .shadow(color: Color.orange.opacity(0.4), radius: 4)

            Text("Auto-paste needs Accessibility permission")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.9))

            Spacer()

            Button("Grant") {
                pasteManager.requestAccessibility()
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .padding(.horizontal, 9)
            .padding(.vertical, 3.5)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.8))
            .shadow(color: Color.orange.opacity(0.35), radius: 3, y: 1)

            Button("Verify") {
                pasteManager.checkAccessibility()
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Color.white.opacity(0.08))
            .foregroundColor(.primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))

            Button(action: { pasteManager.dismissBanner() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 11)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.orange.opacity(0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.4), Color.orange.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
    }

    // MARK: - Settings View
    private var settingsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 13) {
                // Header Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Global Activation Shortcut")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Summon MacClip from anywhere in macOS:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Custom Shortcut Recorder Card
                let isCustomActive = !HotkeySetting.presets.contains(where: { $0.id == hotkeyManager.currentSetting.id })

                if hotkeyManager.isRecording {
                    // Recording Active State (Liquid Amber Glass)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.orange.opacity(0.4), lineWidth: 3)
                                )

                            Text(hotkeyManager.recordingPrompt)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)

                            Spacer()

                            Button(action: {
                                hotkeyManager.stopRecording(cancelled: true)
                            }) {
                                Text("Cancel (Esc)")
                                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.12))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Press any modifier (⌘, ⌥, ⌃) + key. Press Esc to cancel.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(11)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.orange.opacity(0.09))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.orange.opacity(0.45), lineWidth: 1)
                    )
                } else {
                    // Custom Shortcut Card (Liquid Glass)
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: isCustomActive ? "keyboard.fill" : "keyboard")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(isCustomActive ? .accentColor : .secondary)

                                Text("Custom Shortcut")
                                    .font(.system(size: 12, weight: isCustomActive ? .bold : .medium, design: .rounded))

                                if isCustomActive {
                                    Text("ACTIVE")
                                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(isCustomActive ? hotkeyManager.currentSetting.name : "Record your own combination (e.g. ⌘⇧C, ⌃⌥Space)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isCustomActive {
                            Text(hotkeyManager.currentSetting.displayString)
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(Color.accentColor.opacity(0.18))
                                .foregroundColor(.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 0.8)
                                )
                        }

                        Button(action: {
                            hotkeyManager.startRecording()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCustomActive ? "arrow.triangle.2.circlepath" : "record.circle")
                                    .font(.system(size: 10.5, weight: .bold))
                                Text(isCustomActive ? "Change" : "Record")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Record a custom global shortcut")
                    }
                    .padding(11)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(isCustomActive ? Color.accentColor.opacity(0.10) : Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(isCustomActive ? Color.accentColor.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 0.8)
                    )
                }

                // Standard Presets Section
                Text("Or select a standard preset:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)

                VStack(spacing: 5) {
                    ForEach(HotkeySetting.presets, id: \.id) { preset in
                        let isSelected = hotkeyManager.currentSetting.id == preset.id
                        Button(action: {
                            if hotkeyManager.isRecording {
                                hotkeyManager.stopRecording(cancelled: true)
                            }
                            hotkeyManager.updateHotkey(to: preset)
                        }) {
                            HStack {
                                Text(preset.name)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .regular, design: .rounded))
                                Spacer()
                                Text(preset.displayString)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(isSelected ? Color.accentColor : Color.white.opacity(0.07))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 13))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary.opacity(0.3))
                                        .font(.system(size: 13))
                                }
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.white.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().opacity(0.15)
                    .padding(.vertical, 2)

                // Accessibility Permission Card
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Paste Permission")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        Text(pasteManager.isAccessibilityGranted ? "Granted — Keystrokes auto-paste into active apps" : "Click to authorize in macOS System Settings")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    if pasteManager.isAccessibilityGranted {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.green.opacity(0.25), lineWidth: 0.6))
                    } else {
                        Button("Open Settings") {
                            pasteManager.requestAccessibility()
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )

                // Launch at Login Card
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.accentColor)
                            Text("Launch at Login")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        Text("Automatically start MacClip when you log in")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { launchManager.isEnabled },
                        set: { launchManager.setEnabled($0) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )

                // Password Manager Privacy Card
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.purple)
                            Text("Ignore Password Managers")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        Text("Never save clips from 1Password, Bitwarden, or Keychain")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Toggle("", isOn: $store.ignorePasswordManagers)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )

                // History Retention & Storage Card
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11.5))
                                .foregroundColor(.orange)
                            Text("History Retention & Storage")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Text(store.storageInfoText)
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    // Max History Limit Selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MAX HISTORY SIZE")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))

                        HStack(spacing: 4) {
                            ForEach(ClipboardHistoryStore.HistoryLimit.allCases) { limit in
                                let isSelected = store.maxHistoryLimit == limit
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        store.maxHistoryLimit = limit
                                    }
                                }) {
                                    Text(limit.label)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundColor(isSelected ? .white : .secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(isSelected ? Color.accentColor : Color.white.opacity(0.04))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.07), lineWidth: 0.6)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Auto-Cleanup Period Selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AUTO-DELETE UNPINNED CLIPS")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))

                        HStack(spacing: 4) {
                            ForEach(ClipboardHistoryStore.RetentionPeriod.allCases) { period in
                                let isSelected = store.retentionPeriod == period
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        store.retentionPeriod = period
                                    }
                                }) {
                                    Text(period.label)
                                        .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundColor(isSelected ? .white : .secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(isSelected ? Color.orange.opacity(0.85) : Color.white.opacity(0.04))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.07), lineWidth: 0.6)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Cleanup message banner if present
                    if let msg = store.lastCleanupMessage {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text(msg)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .transition(.opacity)
                    }

                    // Action buttons: Clean Up Now, Clear Unpinned, Clear All
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation {
                                _ = store.performAutoCleanup()
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 9.5))
                                Text("Clean Up Now")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Prune expired clips and excess unpinned items immediately")

                        Spacer()

                        Button(action: {
                            store.clearUnpinned()
                        }) {
                            Text("Clear Unpinned")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.05))
                                .foregroundColor(.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            store.clearAll()
                        }) {
                            Text("Clear All")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.25), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )

                // Done Button
                HStack {
                    Spacer()
                    Button(action: {
                        if hotkeyManager.isRecording {
                            hotkeyManager.stopRecording(cancelled: true)
                        }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            store.isSettingsOpen = false
                        }
                    }) {
                        Text("Done")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - List
    private var listView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 7) {
                    ForEach(Array(store.filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            index: index,
                            isSelected: index == store.selectedIndex,
                            onSelect: {
                                onSelect?(item)
                            },
                            onTogglePin: {
                                store.togglePin(id: item.id)
                            },
                            onDelete: {
                                store.delete(id: item.id)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: store.selectedIndex) { targetIdx in
                if targetIdx >= 0 && targetIdx < store.filteredItems.count {
                    let targetId = store.filteredItems[targetIdx].id
                    withAnimation(.easeInOut(duration: 0.12)) {
                        proxy.scrollTo(targetId, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                Image(systemName: store.searchText.isEmpty ? "sparkles.rectangle.stack" : "magnifyingglass")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.accentColor.opacity(0.75))
            }

            if store.searchText.isEmpty {
                Text(store.selectedCategory == .pinned ? "No Pinned Clips" : "Clipboard is Clear")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(store.selectedCategory == .pinned ? "Pin frequently used snippets with the pin icon to keep them here." : "Copy text or screenshots anywhere to build your history.")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            } else {
                Text("No Matching Clips")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("Try searching with different keywords.")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Quick Look View
    private func quickLookView(item: ClipboardItem) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                quickLookHeader(for: item)
                quickLookBody(for: item)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func quickLookHeader(for item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            categoryBadge(for: item)

            if let source = item.sourceApp {
                HStack(spacing: 3) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 9))
                    Text(source)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
            }

            if let dims = item.formattedDimensions {
                Text(dims)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if let size = item.formattedFileSize {
                Text("• \(size)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            Text(item.relativeTimeString)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func quickLookBody(for item: ClipboardItem) -> some View {
        if item.itemType == .image, let path = item.imagePath, let nsImage = ImageCache.shared.image(for: path) {
            quickLookImageView(item: item, path: path, nsImage: nsImage)
        } else if item.category == .color {
            quickLookColorView(item: item)
        } else if item.category == .url {
            quickLookUrlView(item: item)
        } else {
            quickLookTextView(item: item)
        }
    }

    private func quickLookImageView(item: ClipboardItem, path: String, nsImage: NSImage) -> some View {
        VStack(spacing: 12) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)

            HStack(spacing: 8) {
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                        Text("Open in Preview")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    onSelect?(item)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.turn.down.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Paste Image (↵)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func quickLookColorView(item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            colorSwatchRow(item: item)
            colorPillsRow(item: item)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func colorSwatchRow(item: ClipboardItem) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hexString: item.text))
                .frame(width: 72, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.system(size: 19, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                if let rgb = item.rgbColorString {
                    Text(rgb)
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if let hsl = item.hslColorString {
                    Text(hsl)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
    }

    @ViewBuilder
    private func colorPillsRow(item: ClipboardItem) -> some View {
        HStack(spacing: 6) {
            ColorCopyPill(key: "HEX", value: item.text)

            if let rgb = item.rgbColorString {
                ColorCopyPill(key: "RGB", value: rgb)
            }

            if let hsl = item.hslColorString {
                ColorCopyPill(key: "HSL", value: hsl)
            }

            Spacer()

            Button(action: {
                onSelect?(item)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.left")
                        .font(.system(size: 9, weight: .bold))
                    Text("Paste (↵)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(0.35), radius: 4, y: 1)
            }
            .buttonStyle(.plain)
        }
    }

    private func quickLookUrlView(item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            urlHostHeader(item: item)
            urlTextBox(item: item)
            urlActionsRow(item: item)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func urlHostHeader(item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)

            if let url = URL(string: item.text), let host = url.host {
                Text(host)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
        }
    }

    private func urlTextBox(item: ClipboardItem) -> some View {
        Text(item.text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.primary)
            .lineLimit(4)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func urlActionsRow(item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            if let url = URL(string: item.text) {
                Button("Open Browser") {
                    NSWorkspace.shared.open(url)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            let clean = cleanURL(item.text)
            if clean != item.text {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(clean, forType: .string)
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        store.copiedFeedbackKey = "clean"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        if store.copiedFeedbackKey == "clean" {
                            withAnimation { store.copiedFeedbackKey = nil }
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        if store.copiedFeedbackKey == "clean" {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        Text(store.copiedFeedbackKey == "clean" ? "Clean Copied ✓" : "Clean URL")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Spacer()

            Button(action: {
                onSelect?(item)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.left")
                        .font(.system(size: 9, weight: .bold))
                    Text("Paste (↵)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func quickLookTextView(item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            textStatsRow(item: item)
            textScrollBox(item: item)
            textTransformActions(item: item)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func textStatsRow(item: ClipboardItem) -> some View {
        let charCount = item.text.count
        let wordCount = item.text.split { $0.isWhitespace || $0.isNewline }.count
        let lineCount = item.text.split(separator: "\n", omittingEmptySubsequences: false).count

        return HStack(spacing: 8) {
            Text("\(charCount) chars")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
            Text("•")
                .foregroundColor(.secondary.opacity(0.5))
            Text("\(wordCount) words")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
            Text("•")
                .foregroundColor(.secondary.opacity(0.5))
            Text("\(lineCount) lines")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    private func textScrollBox(item: ClipboardItem) -> some View {
        ScrollView {
            Text(item.text)
                .font(.system(size: 12, design: item.category == .code ? .monospaced : .default))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .frame(maxHeight: 200)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func textTransformActions(item: ClipboardItem) -> some View {
        HStack(spacing: 5) {
            Button("UPPER") {
                let transformed = item.text.uppercased()
                AppDelegate.shared?.paste(item: ClipboardItem(text: transformed), plainText: true)
            }
            .font(.system(size: 9.5, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button("lower") {
                let transformed = item.text.lowercased()
                AppDelegate.shared?.paste(item: ClipboardItem(text: transformed), plainText: true)
            }
            .font(.system(size: 9.5, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button("Title Case") {
                let transformed = item.text.capitalized
                AppDelegate.shared?.paste(item: ClipboardItem(text: transformed), plainText: true)
            }
            .font(.system(size: 9.5, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
            .controlSize(.mini)

            if let pretty = prettifyJSON(item.text) {
                Button("Format JSON") {
                    AppDelegate.shared?.paste(item: ClipboardItem(text: pretty), plainText: true)
                }
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            Spacer()

            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.text, forType: .string)
            }
            .font(.system(size: 10.5, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: {
                AppDelegate.shared?.paste(item: item, plainText: true)
            }) {
                Text("⇧↵ Plain")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("Paste as plain text (⇧↵)")

            Button(action: {
                onSelect?(item)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.left")
                        .font(.system(size: 9, weight: .bold))
                    Text("Paste (↵)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func categoryBadge(for item: ClipboardItem) -> some View {
        HStack(spacing: 3) {
            Image(systemName: item.category.iconName)
                .font(.system(size: 9.5))
            Text(item.category.rawValue)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeColor(for: item).opacity(0.18))
        .foregroundColor(badgeColor(for: item))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(badgeColor(for: item).opacity(0.25), lineWidth: 0.6)
        )
    }

    private func badgeColor(for item: ClipboardItem) -> Color {
        switch item.category {
        case .image: return .indigo
        case .url: return .blue
        case .color: return .purple
        case .code: return .green
        case .email: return .orange
        case .text: return .secondary
        }
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            // Count indicators
            // Left Group: Count indicators & Clear Unpinned
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 9))
                    Text("\(store.items.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.6))

                let pinnedCount = store.items.filter { $0.isPinned }.count
                if pinnedCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                        Text("\(pinnedCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.orange.opacity(0.25), lineWidth: 0.6))
                }

                if !store.items.isEmpty && !store.isSettingsOpen {
                    Button(action: {
                        withAnimation {
                            store.clearUnpinned()
                        }
                    }) {
                        Text("Clear Unpinned")
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.04))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Clear all unpinned clips")
                }
            }

            Spacer(minLength: 10)

            // Right Group: Keyboard shortcut hints (guaranteed non-wrapping)
            HStack(spacing: 4.5) {
                footerKeycapHint(key: "↵", label: "Paste")
                footerKeycapHint(key: "⇧↵", label: "Plain")
                footerKeycapHint(key: "Space", label: "Preview")
                footerKeycapHint(key: "⌘⌫", label: "Del")
            }
        }
    }

    private func footerKeycapHint(key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(.primary.opacity(0.9))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6)
                )
                .lineLimit(1)
                .fixedSize()

            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.9))
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2.5)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
        )
        .fixedSize()
    }
}

// MARK: - Color Copy Pill
struct ColorCopyPill: View {
    let key: String
    let value: String
    @ObservedObject var store = ClipboardHistoryStore.shared

    private var isCopied: Bool {
        store.copiedFeedbackKey == key
    }

    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                store.copiedFeedbackKey = key
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                if store.copiedFeedbackKey == key {
                    withAnimation { store.copiedFeedbackKey = nil }
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 8.5, weight: .bold))
                Text(isCopied ? "Copied ✓" : key)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4.5)
            .background(isCopied ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
            .foregroundColor(isCopied ? .green : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isCopied ? Color.green.opacity(0.4) : Color.white.opacity(0.15),
                    lineWidth: 0.6
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Apple Keycap Badge (⌘1..⌘9)
struct AppleKeycapBadge: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(isSelected ? .accentColor : .primary.opacity(0.85))
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(
                LinearGradient(
                    colors: isSelected
                    ? [Color.accentColor.opacity(0.25), Color.accentColor.opacity(0.12)]
                    : [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                            ? [Color.accentColor.opacity(0.7), Color.accentColor.opacity(0.3)]
                            : [Color.white.opacity(0.30), Color.white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 1, y: 1)
    }
}

// MARK: - Item Row Card (Liquid Glass Style)
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let isRowHovered = (ClipboardHistoryStore.shared.hoveredIndex == index)
        HStack(alignment: .center, spacing: 8) {
            cardContent
            rowActions(isRowHovered: isRowHovered)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(rowBackground(isRowHovered: isRowHovered))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(rowOverlayBorder(isRowHovered: isRowHovered))
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.20) : (isRowHovered ? Color.black.opacity(0.08) : Color.clear),
            radius: isSelected ? 6 : 3,
            y: isSelected ? 2 : 1
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isSelected)
        .onHover { hovering in
            if hovering {
                ClipboardHistoryStore.shared.hoveredIndex = index
            } else if ClipboardHistoryStore.shared.hoveredIndex == index {
                ClipboardHistoryStore.shared.hoveredIndex = nil
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                if index < 9 {
                    AppleKeycapBadge(text: "⌘\(index + 1)", isSelected: isSelected)
                        .padding(.top, 2)
                } else {
                    Spacer().frame(width: 24)
                }

                VStack(alignment: .leading, spacing: 5) {
                    rowMetadataHeader
                    rowItemPreview
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var rowMetadataHeader: some View {
        HStack(spacing: 6) {
            categoryBadge

            if let source = item.sourceApp {
                Text(source)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if let dims = item.formattedDimensions {
                Text(dims)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            if let size = item.formattedFileSize {
                Text("• \(size)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            Text(item.relativeTimeString)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    @ViewBuilder
    private var rowItemPreview: some View {
        if item.itemType == .image, let path = item.imagePath, let nsImage = ImageCache.shared.image(for: path) {
            rowImagePreview(nsImage: nsImage)
        } else if item.category == .color {
            rowColorPreview
        } else if item.category == .code {
            Text(item.text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(3)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        } else if item.category == .url {
            Text(item.text)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.blue.opacity(0.95))
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(item.text)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(3)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rowImagePreview(nsImage: NSImage) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 115)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )

            if let dims = item.formattedDimensions {
                Text(dims)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6)
                    )
                    .padding(4)
            }
        }
        .padding(.vertical, 2)
    }

    private var rowColorPreview: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                .fill(Color(hexString: item.text))
                .frame(width: 15, height: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 1.5, y: 0.5)

            Text(item.text)
                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)

            if let rgb = item.rgbColorString {
                Text(rgb)
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func rowActions(isRowHovered: Bool) -> some View {
        HStack(spacing: 5) {
            if isSelected || isRowHovered {
                Button(action: {
                    ClipboardHistoryStore.shared.togglePreview(for: item)
                }) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .padding(5.5)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6)
                        )
                }
                .buttonStyle(.plain)
                .help("Quick Look preview (Space)")

                Button(action: onSelect) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.turn.down.left")
                            .font(.system(size: 8, weight: .bold))
                        Text("Paste")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                    )
                    .shadow(color: Color.accentColor.opacity(0.38), radius: 4, y: 1.5)
                }
                .buttonStyle(.plain)
                .help("Paste into current app (↵) • Hold Shift for plain text (⇧↵)")
            }

            Button(action: onTogglePin) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10.5))
                    .foregroundColor(item.isPinned ? .orange : .secondary.opacity(0.5))
                    .padding(5.5)
                    .background(
                        item.isPinned
                        ? Color.orange.opacity(0.18)
                        : Color.white.opacity(0.04)
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle().strokeBorder(
                            item.isPinned
                            ? Color.orange.opacity(0.35)
                            : Color.white.opacity(0.10),
                            lineWidth: 0.6
                        )
                    )
                    .shadow(color: item.isPinned ? Color.orange.opacity(0.2) : Color.clear, radius: 3)
            }
            .buttonStyle(.plain)
            .help(item.isPinned ? "Unpin clip (⌘P)" : "Pin clip (⌘P)")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.45))
                    .padding(5.5)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
                    .overlay(
                        Circle().strokeBorder(
                            Color.white.opacity(0.08),
                            lineWidth: 0.6
                        )
                    )
            }
            .buttonStyle(.plain)
            .help("Delete clip (⌘⌫)")
        }
    }

    @ViewBuilder
    private func rowBackground(isRowHovered: Bool) -> some View {
        if isSelected {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.20),
                    Color.accentColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isRowHovered {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.032)
        }
    }

    private func rowOverlayBorder(isRowHovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .strokeBorder(
                isSelected
                ? LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.85),
                        Color.white.opacity(0.45),
                        Color.accentColor.opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        Color.white.opacity(isRowHovered ? 0.22 : 0.08),
                        Color.white.opacity(isRowHovered ? 0.06 : 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isSelected ? 1.2 : 0.75
            )
    }

    @ViewBuilder
    private var categoryBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: item.category.iconName)
                .font(.system(size: 8.5, weight: .bold))
            Text(item.category.rawValue.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.14))
        .foregroundColor(badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                .stroke(badgeColor.opacity(0.25), lineWidth: 0.6)
        )
    }

    private var badgeColor: Color {
        switch item.category {
        case .image: return .indigo
        case .url: return .blue
        case .color: return .purple
        case .code: return .green
        case .email: return .orange
        case .text: return .secondary
        }
    }
}

// MARK: - Native Window Dragging View
public struct WindowDragArea: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> DragView {
        DragView()
    }

    public func updateNSView(_ nsView: DragView, context: Context) {}

    public final class DragView: NSView {
        private var initialMouseLocation: NSPoint = .zero
        private var initialWindowOrigin: NSPoint = .zero

        public override func resetCursorRects() {
            addCursorRect(bounds, cursor: .openHand)
        }

        public override func mouseDown(with event: NSEvent) {
            initialMouseLocation = NSEvent.mouseLocation
            if let window = self.window {
                initialWindowOrigin = window.frame.origin
                if let panel = window as? FloatingPanel {
                    panel.hasUserMovedWindow = true
                }
            }
        }

        public override func mouseDragged(with event: NSEvent) {
            guard let window = self.window else { return }
            let current = NSEvent.mouseLocation
            let dx = current.x - initialMouseLocation.x
            let dy = current.y - initialMouseLocation.y
            window.setFrameOrigin(NSPoint(
                x: initialWindowOrigin.x + dx,
                y: initialWindowOrigin.y + dy
            ))
        }
    }
}

// MARK: - Frosted Liquid Glass Background
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        view.wantsLayer = true
        view.layer?.cornerRadius = 22
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.layer?.cornerRadius = 22
        nsView.layer?.masksToBounds = true
    }
}

// MARK: - Helper Functions
func prettifyJSON(_ str: String) -> String? {
    guard let data = str.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data, options: []),
          let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
          let prettyString = String(data: prettyData, encoding: .utf8) else {
        return nil
    }
    return prettyString
}

func cleanURL(_ urlString: String) -> String {
    guard let url = URL(string: urlString),
          var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return urlString
    }
    let trackingParams: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "fbclid", "gclid", "msclkid", "ref", "igshid", "mc_cid", "mc_eid",
        "yclid", "_hsenc", "_hsmi", "mkt_tok"
    ]
    if let existing = components.queryItems {
        let filtered = existing.filter { !trackingParams.contains($0.name.lowercased()) }
        components.queryItems = filtered.isEmpty ? nil : filtered
    }
    return components.string ?? urlString
}

extension Color {
    init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        else if hex.lowercased().hasPrefix("0x") { hex.removeFirst(2) }

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
