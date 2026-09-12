import SwiftUI
import AppKit

public struct ClipboardHistoryView: View {
    @ObservedObject var store = ClipboardHistoryStore.shared
    @ObservedObject var hotkeyManager = GlobalHotKeyManager.shared
    @ObservedObject var pasteManager = PasteManager.shared

    public var onSelect: ((ClipboardItem) -> Void)?
    public var onClose: (() -> Void)?

    public init(onSelect: ((ClipboardItem) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Glass Header: Search & Glass Action Buttons
            headerView
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)

            // Category Filter Pills (All, Pinned, Text, Images, Links)
            if !store.isSettingsOpen {
                categoryFilterBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            // Accessibility Notice (Liquid Amber Glass Banner)
            if !pasteManager.isAccessibilityGranted && !pasteManager.isBannerDismissed && !store.isSettingsOpen {
                accessibilityBanner
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            // Subtle Glass Separator
            glassDivider

            // Content Area
            if store.isSettingsOpen {
                settingsView
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
        .frame(width: 440, height: 570)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Glass Separator
    private var glassDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
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
            } else {
                // Search Pill
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(store.searchText.isEmpty ? .secondary.opacity(0.7) : .accentColor)
                        .font(.system(size: 13, weight: .medium))

                    TextField("Search clips, links, images...", text: $store.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onSubmit {
                            if !store.filteredItems.isEmpty && store.selectedIndex < store.filteredItems.count {
                                onSelect?(store.filteredItems[store.selectedIndex])
                            }
                        }

                    if !store.searchText.isEmpty {
                        Button(action: { store.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )

                // Settings Toggle Icon
                Button(action: {
                    if store.isSettingsOpen && hotkeyManager.isRecording {
                        hotkeyManager.stopRecording(cancelled: true)
                    }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        store.isSettingsOpen.toggle()
                    }
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(7)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help("Preferences & Shortcuts")

                // Close Button
                Button(action: {
                    if hotkeyManager.isRecording {
                        hotkeyManager.stopRecording(cancelled: true)
                    }
                    onClose?()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(7)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }
        }
    }

    // MARK: - Category Filter Bar
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(ClipboardHistoryStore.FilterCategory.allCases) { category in
                    let isSelected = store.selectedCategory == category
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.14)) {
                            store.selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))

                            Text(category.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))

                            let c = store.count(for: category)
                            if c > 0 {
                                Text("\(c)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(isSelected ? Color.white.opacity(0.28) : Color.primary.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Group {
                                if isSelected {
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.9), Color.accentColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color.white.opacity(0.05)
                                }
                            }
                        )
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.75))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? Color.white.opacity(0.35) : Color.white.opacity(0.10),
                                    lineWidth: 0.8
                                )
                        )
                        .shadow(color: isSelected ? Color.accentColor.opacity(0.35) : Color.clear, radius: 4, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Accessibility Banner
    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(.orange)
                .font(.system(size: 12))

            Text("Auto-paste needs Accessibility permission")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary.opacity(0.85))

            Spacer()

            Button("Grant") {
                pasteManager.requestAccessibility()
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange)
            .foregroundColor(.white)
            .clipShape(Capsule())

            Button("Verify") {
                pasteManager.checkAccessibility()
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))

            Button(action: { pasteManager.dismissBanner() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(0.3), lineWidth: 0.8)
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
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            // Count indicators
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 9.5))
                    Text("\(store.items.count)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
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
                            .font(.system(size: 8.5))
                        Text("\(pinnedCount)")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.orange.opacity(0.25), lineWidth: 0.6))
                }
            }

            Spacer()

            if !store.items.isEmpty && !store.isSettingsOpen {
                Button("Clear Unpinned") {
                    withAnimation {
                        store.clearUnpinned()
                    }
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                .buttonStyle(.plain)
            }

            // Keyboard hints
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text("↵")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                    Text("Paste")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(hotkeyManager.currentSetting.displayString)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                    )
            }
        }
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
        HStack(alignment: .center, spacing: 8) {
            // Main clickable card area
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 10) {
                    // Quick shortcut badge (⌘1..⌘9)
                    if index < 9 {
                        Text("⌘\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.8))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2.5)
                            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 0.6)
                            )
                            .padding(.top, 2)
                    } else {
                        Spacer().frame(width: 24)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        // Metadata header
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

                        // Preview: Image or Text
                        if item.itemType == .image, let path = item.imagePath, let nsImage = NSImage(contentsOfFile: path) {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Actions: Paste, Pin, Trash
            HStack(spacing: 5) {
                let isHovered = ClipboardHistoryStore.shared.hoveredIndex == index
                if isSelected || isHovered {
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
                            Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                        )
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 4, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help("Paste into current app (↵)")
                }

                Button(action: onTogglePin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(item.isPinned ? .orange : .secondary.opacity(0.45))
                        .padding(5)
                        .background(Color.white.opacity(item.isPinned ? 0.12 : 0.04))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(item.isPinned ? 0.25 : 0.08), lineWidth: 0.6)
                        )
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin clip" : "Pin clip")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary.opacity(0.45))
                        .padding(5)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                        )
                }
                .buttonStyle(.plain)
                .help("Delete clip")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.18),
                            Color.accentColor.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else if ClipboardHistoryStore.shared.hoveredIndex == index {
                    Color.white.opacity(0.07)
                } else {
                    Color.white.opacity(0.03)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(
                    isSelected
                    ? LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.75),
                            Color.white.opacity(0.35),
                            Color.accentColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [
                            Color.white.opacity((ClipboardHistoryStore.shared.hoveredIndex == index) ? 0.22 : 0.08),
                            Color.white.opacity((ClipboardHistoryStore.shared.hoveredIndex == index) ? 0.08 : 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 1.2 : 0.8
                )
        )
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
            radius: 5,
            y: 1.5
        )
        .onHover { isHovering in
            if isHovering {
                ClipboardHistoryStore.shared.hoveredIndex = index
            } else if ClipboardHistoryStore.shared.hoveredIndex == index {
                ClipboardHistoryStore.shared.hoveredIndex = nil
            }
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
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
