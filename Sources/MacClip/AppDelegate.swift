import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    private var panel: FloatingPanel?
    private var menuBarController: MenuBarController?
    private var previousApp: NSRunningApplication?

    public override init() {
        super.init()
        AppDelegate.shared = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
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
        let panelRect = NSRect(x: 0, y: 0, width: 430, height: 530)
        let floatingPanel = FloatingPanel(contentRect: panelRect)

        let contentView = ClipboardHistoryView(
            onSelect: { [weak self] item in
                self?.paste(item: item)
            },
            onClose: { [weak self] in
                self?.hidePanel()
            }
        )

        floatingPanel.contentView = NSHostingView(rootView: contentView)
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

    public func showPanel() {
        guard let panel = panel else { return }

        // Recheck accessibility permission on show
        PasteManager.shared.checkAccessibility()

        // Save active application to restore focus later for auto-pasting
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = frontmost
        }

        // Reset search query and selection on show
        ClipboardHistoryStore.shared.searchText = ""
        ClipboardHistoryStore.shared.selectedIndex = 0
        ClipboardHistoryStore.shared.isSettingsOpen = false

        panel.positionNearMouseOrCenter()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hidePanel() {
        panel?.orderOut(nil)
    }

    public func paste(item: ClipboardItem) {
        hidePanel()
        PasteManager.shared.paste(item: item, targetApp: previousApp)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyManager.shared.unregister()
        ClipboardMonitor.shared.stopMonitoring()
    }
}
