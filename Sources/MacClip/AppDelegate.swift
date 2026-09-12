import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    private var panel: FloatingPanel?
    private var menuBarController: MenuBarController?
    public private(set) var targetApp: NSRunningApplication?

    public override init() {
        super.init()
        AppDelegate.shared = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logTrace("MacClip applicationDidFinishLaunching")

        // Start clipboard change observer
        ClipboardMonitor.shared.startMonitoring()

        // Check accessibility status
        PasteManager.shared.checkAccessibility()

        // Setup Menu Bar icon
        menuBarController = MenuBarController()

        // Setup Floating Window
        setupPanel()

        // Register custom or default hotkey
        GlobalHotKeyManager.shared.onHotKeyPressed = { [weak self] in
            self?.togglePanel()
        }
        GlobalHotKeyManager.shared.register()

        print("MacClip successfully launched.")
    }

    private func setupPanel() {
        let panelRect = NSRect(x: 0, y: 0, width: 440, height: 570)
        let floatingPanel = FloatingPanel(contentRect: panelRect)
        self.panel = floatingPanel
    }

    public func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    public func showPanel(showSettings: Bool = false) {
        guard let panel = panel else { return }

        // Capture frontmost application before showing the panel
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.targetApp = front
            logTrace("Captured targetApp: \(front.localizedName ?? "") (\(front.bundleIdentifier ?? ""))")
        }

        // Recheck accessibility permission on show
        PasteManager.shared.checkAccessibility()

        // Reset search query, selection, settings, and preview on show
        ClipboardHistoryStore.shared.searchText = ""
        ClipboardHistoryStore.shared.selectedIndex = 0
        ClipboardHistoryStore.shared.hoveredIndex = nil
        ClipboardHistoryStore.shared.previewItem = nil
        ClipboardHistoryStore.shared.isSettingsOpen = showSettings

        // Attach fresh NSHostingView so all items render with up-to-date state
        let contentView = ClipboardHistoryView(
            onSelect: { [weak self] item in
                self?.paste(item: item)
            },
            onClose: { [weak self] in
                self?.hidePanel()
            }
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        panel.positionNearMouseOrCenter()
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        panel.startClickOutsideMonitor()
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        togglePanel()
        return true
    }

    public func hidePanel() {
        GlobalHotKeyManager.shared.stopRecording(cancelled: true)
        ClipboardHistoryStore.shared.previewItem = nil
        panel?.stopClickOutsideMonitor()
        panel?.orderOut(nil)
    }

    public func paste(item: ClipboardItem, plainText: Bool = false) {
        let target = self.targetApp
        logTrace("AppDelegate.paste invoked for item: \(item.id), plainText: \(plainText), targetApp: \(target?.localizedName ?? "nil")")
        hidePanel()
        PasteManager.shared.paste(item: item, targetApp: target, plainText: plainText)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyManager.shared.unregister()
        ClipboardMonitor.shared.stopMonitoring()
    }
}
