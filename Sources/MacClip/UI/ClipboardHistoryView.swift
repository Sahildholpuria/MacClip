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
            // Header
            headerView
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Accessibility Banner (dismissible)
            if !pasteManager.isAccessibilityGranted && !pasteManager.isBannerDismissed && !store.isSettingsOpen {
                accessibilityBanner
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            Divider()
                .opacity(0.3)

            // Main Content: Settings View or Clips List
            if store.isSettingsOpen {
                settingsView
            } else if store.filteredItems.isEmpty {
                emptyStateView
            } else {
                listView
            }

            Divider()
                .opacity(0.3)

            // Footer
            footerView
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .frame(width: 430, height: 530)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 8) {
            if store.isSettingsOpen {
                Text("Preferences")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { store.isSettingsOpen = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Clips")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))

                TextField("Search clips & images...", text: $store.searchText)
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
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { store.isSettingsOpen.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Settings & Shortcuts")

                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }
        }
        .padding(.vertical, store.isSettingsOpen ? 4 : 8)
        .padding(.horizontal, 10)
        .background(store.isSettingsOpen ? Color.clear : Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Accessibility Banner
    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(.orange)
                .font(.system(size: 11))

            Text("Auto-paste needs Accessibility")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            Button("Grant") {
                pasteManager.requestAccessibility()
            }
            .font(.system(size: 10, weight: .medium))
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)

            Button("Verify") {
                pasteManager.checkAccessibility()
            }
            .font(.system(size: 10))
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button(action: { pasteManager.dismissBanner() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(3)
            }
            .buttonStyle(.plain)
            .help("Dismiss notice")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Settings View
    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Global Activation Shortcut")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Text("Choose the key combination to summon MacClip from anywhere:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                ForEach(HotkeySetting.presets, id: \.id) { preset in
                    let isSelected = hotkeyManager.currentSetting.id == preset.id
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        }
                        Spacer()
                        Text(preset.displayString)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 5))

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 13))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary.opacity(0.4))
                                .font(.system(size: 13))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hotkeyManager.updateHotkey(to: preset)
                    }
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Accessibility Status in Settings
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Paste Permission")
                        .font(.system(size: 12, weight: .semibold))
                    Text(pasteManager.isAccessibilityGranted ? "Granted (Keystrokes will auto-paste)" : "Not granted (Click to open System Settings)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()

                if pasteManager.isAccessibilityGranted {
                    Label("Active", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Button("Open Settings") {
                        pasteManager.requestAccessibility()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    store.isSettingsOpen = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - List
    private var listView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
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
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 42))
                .foregroundColor(.secondary.opacity(0.4))

            if store.searchText.isEmpty {
                Text("Clipboard is Empty")
                    .font(.system(size: 15, weight: .medium))
                Text("Copy text or screenshots anywhere to build your history.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("No Matching Clips")
                    .font(.system(size: 15, weight: .medium))
                Text("Try searching with different keywords.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            HStack(spacing: 6) {
                Label("\(store.items.count)", systemImage: "doc.on.clipboard")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                let pinnedCount = store.items.filter { $0.isPinned }.count
                if pinnedCount > 0 {
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.4))
                    Label("\(pinnedCount)", systemImage: "pin.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            if !store.items.isEmpty && !store.isSettingsOpen {
                Button("Clear") {
                    store.clearUnpinned()
                }
                .font(.system(size: 11))
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary.opacity(0.4))
            }

            HStack(spacing: 4) {
                Text("↵ Paste")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary.opacity(0.4))
                Text(hotkeyManager.currentSetting.displayString)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Item Row
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Main clickable item body
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 10) {
                    // Quick-select index tag (1..9)
                    if index < 9 {
                        Text("⌘\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(.top, 2)
                    } else {
                        Spacer().frame(width: 24)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Category & Metadata header
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
                                    .foregroundColor(.secondary.opacity(0.7))
                            }

                            Spacer()

                            Text(item.relativeTimeString)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        // Main content preview
                        if item.itemType == .image, let path = item.imagePath, let nsImage = NSImage(contentsOfFile: path) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                                .padding(.vertical, 2)
                        } else {
                            Text(item.text)
                                .font(.system(size: 12))
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

            // Quick actions
            HStack(spacing: 4) {
                let isHovered = ClipboardHistoryStore.shared.hoveredIndex == index
                if isSelected || isHovered {
                    Button(action: onSelect) {
                        Text("Paste")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .help("Paste into current app (↵)")
                }

                Button(action: onTogglePin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(item.isPinned ? .orange : .secondary.opacity(0.5))
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin clip" : "Pin clip")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help("Delete clip")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : ((ClipboardHistoryStore.shared.hoveredIndex == index) ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
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
                .font(.system(size: 9))
            Text(item.category.rawValue)
                .font(.system(size: 9, weight: .semibold))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.12))
        .foregroundColor(badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
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

// MARK: - Frosted Glass Background
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
