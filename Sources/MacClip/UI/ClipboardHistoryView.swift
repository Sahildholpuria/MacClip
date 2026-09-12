import SwiftUI
import AppKit

public struct ClipboardHistoryView: View {
    @ObservedObject var store = ClipboardHistoryStore.shared
    public var onSelect: ((ClipboardItem) -> Void)?
    public var onClose: (() -> Void)?

    public init(onSelect: ((ClipboardItem) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: Search & Close
            headerView
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if !PasteManager.shared.isAccessibilityGranted {
                accessibilityBanner
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            Divider()
                .opacity(0.3)

            // Content List
            if store.filteredItems.isEmpty {
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
        .frame(width: 420, height: 530)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Accessibility Banner
    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(.orange)
                .font(.system(size: 11))

            Text("Auto-paste needs Accessibility permission")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            Button("Grant") {
                PasteManager.shared.requestAccessibility()
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .medium))

            TextField("Search clipboard (e.g. text, link, code)...", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))

            if !store.searchText.isEmpty {
                Button(action: { store.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }

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
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                        .id(index)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: store.selectedIndex) { targetIdx in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(targetIdx, anchor: .center)
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
                Text("Copy text anywhere with ⌘C to build your history.")
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

            if !store.items.isEmpty {
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
                Text("⌥V")
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

            VStack(alignment: .leading, spacing: 5) {
                // Category & Metadata header
                HStack(spacing: 6) {
                    categoryBadge

                    if let source = item.sourceApp {
                        Text(source)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(item.relativeTimeString)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                // Main content preview
                Text(item.text)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Quick actions
            HStack(spacing: 4) {
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
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
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
