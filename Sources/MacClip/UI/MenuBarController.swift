import AppKit

public final class MenuBarController {
    private var statusItem: NSStatusItem?

    public init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Use SF Symbol clipboard icon
        let imageConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "MacClip")?.withSymbolConfiguration(imageConfig) {
            button.image = image
        } else {
            button.title = "📋"
        }

        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            AppDelegate.shared?.togglePanel()
        }
    }

    public func showMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Show Clipboard History", action: #selector(openClipboard), keyEquivalent: "v")
        openItem.keyEquivalentModifierMask = [.option]
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Accessibility status
        let isTrusted = PasteManager.shared.isAccessibilityGranted
        let accessItem = NSMenuItem(
            title: isTrusted ? "Accessibility: Granted ✓" : "Grant Accessibility Permission…",
            action: isTrusted ? nil : #selector(requestAccessibility),
            keyEquivalent: ""
        )
        accessItem.target = self
        if !isTrusted {
            accessItem.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
        }
        menu.addItem(accessItem)

        let clearItem = NSMenuItem(title: "Clear Unpinned History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit MacClip", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // clear menu so left-click continues toggling
    }

    @objc private func openClipboard() {
        AppDelegate.shared?.showPanel()
    }

    @objc private func requestAccessibility() {
        PasteManager.shared.requestAccessibility()
    }

    @objc private func clearHistory() {
        ClipboardHistoryStore.shared.clearUnpinned()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
