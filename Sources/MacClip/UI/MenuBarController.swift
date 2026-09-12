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
        let hotkey = GlobalHotKeyManager.shared.currentSetting

        let openItem = NSMenuItem(
            title: "Show Clipboard History (\(hotkey.displayString))",
            action: #selector(openClipboard),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        // Shortcut submenu
        let shortcutMenu = NSMenu()
        let isPreset = HotkeySetting.presets.contains(where: { $0.id == hotkey.id })
        if !isPreset {
            let customItem = NSMenuItem(title: "\(hotkey.name) (\(hotkey.displayString))", action: nil, keyEquivalent: "")
            customItem.state = .on
            shortcutMenu.addItem(customItem)
            shortcutMenu.addItem(NSMenuItem.separator())
        }
        for preset in HotkeySetting.presets {
            let item = NSMenuItem(title: "\(preset.name) (\(preset.displayString))", action: #selector(changeShortcutPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset
            if preset.id == hotkey.id {
                item.state = .on
            }
            shortcutMenu.addItem(item)
        }
        shortcutMenu.addItem(NSMenuItem.separator())
        let recordItem = NSMenuItem(title: "Record Custom Shortcut…", action: #selector(openPreferences), keyEquivalent: "")
        recordItem.target = self
        shortcutMenu.addItem(recordItem)

        let shortcutItem = NSMenuItem(title: "Shortcut", action: nil, keyEquivalent: "")
        shortcutItem.submenu = shortcutMenu
        menu.addItem(shortcutItem)

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

    @objc private func changeShortcutPreset(_ sender: NSMenuItem) {
        if let preset = sender.representedObject as? HotkeySetting {
            GlobalHotKeyManager.shared.updateHotkey(to: preset)
        }
    }

    @objc private func openClipboard() {
        AppDelegate.shared?.showPanel()
    }

    @objc private func openPreferences() {
        AppDelegate.shared?.showPanel(showSettings: true)
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
