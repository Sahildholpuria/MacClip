import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    private var panel: FloatingPanel?
    private var menuBarController: MenuBarController?
    public private(set) var previousApp: NSRunningApplication?

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
        if let frontmost = frontmost, frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = frontmost
        } else if self.previousApp == nil || self.previousApp?.isTerminated == true {
            self.previousApp = NSWorkspace.shared.runningApplications.first {
                $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
            }
        }

        // Reset search query, selection, and settings on show
        ClipboardHistoryStore.shared.searchText = ""
        ClipboardHistoryStore.shared.selectedIndex = 0
        ClipboardHistoryStore.shared.isSettingsOpen = false

        // Attach fresh NSHostingView so all items render with up-to-date state
        let contentView = ClipboardHistoryView(
            onSelect: { [weak self] item in
                self?.paste(item: item)
            },
            onClose: { [weak self] in
                self?.hidePanel()
            }
        )
        panel.contentView = NSHostingView(rootView: contentView)

        panel.positionNearMouseOrCenter()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hidePanel() {
        panel?.orderOut(nil)
    }

    public func paste(item: ClipboardItem) {
        let target = self.previousApp
        PasteManager.shared.paste(item: item, targetApp: target)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        GlobalHotKeyManager.shared.unregister()
        ClipboardMonitor.shared.stopMonitoring()
    }
}
