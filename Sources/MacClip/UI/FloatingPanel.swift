import AppKit
import SwiftUI

public final class FloatingPanel: NSPanel {
    private var clickOutsideMonitor: Any?

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.animationBehavior = .utilityWindow
    }

    public func startClickOutsideMonitor() {
        stopClickOutsideMonitor()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isVisible else { return }
            let mouseLoc = NSEvent.mouseLocation
            if !self.frame.contains(mouseLoc) {
                logTrace("Click outside panel detected at \(mouseLoc), hiding panel")
                AppDelegate.shared?.hidePanel()
            }
        }
    }

    public func stopClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return false // Never take main app status away from active app
    }

    public override func cancelOperation(_ sender: Any?) {
        AppDelegate.shared?.hidePanel()
    }

    public override func sendEvent(_ event: NSEvent) {
        if event.type == .flagsChanged && GlobalHotKeyManager.shared.isRecording {
            let relevantFlags = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if !relevantFlags.isEmpty {
                var str = ""
                if relevantFlags.contains(.control) { str += "⌃" }
                if relevantFlags.contains(.option) { str += "⌥" }
                if relevantFlags.contains(.shift) { str += "⇧" }
                if relevantFlags.contains(.command) { str += "⌘" }
                GlobalHotKeyManager.shared.recordingPrompt = "\(str) + key..."
            } else {
                GlobalHotKeyManager.shared.recordingPrompt = "Press keys..."
            }
            return
        }

        if event.type == .keyDown {
            // Check if user is currently recording a custom shortcut
            if GlobalHotKeyManager.shared.isRecording {
                // Cancel recording on Escape
                if event.keyCode == 53 && event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
                    GlobalHotKeyManager.shared.stopRecording(cancelled: true)
                    return
                }

                let relevantFlags = event.modifierFlags.intersection([.command, .option, .control, .shift])
                let hasModifier = relevantFlags.contains(.command) || relevantFlags.contains(.option) || relevantFlags.contains(.control)

                // Modifier keys pressed alone (Command, Option, Shift, Control)
                let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
                if modifierKeyCodes.contains(event.keyCode) {
                    GlobalHotKeyManager.shared.recordingPrompt = "Hold key + letter..."
                    return
                }

                if !hasModifier {
                    GlobalHotKeyManager.shared.recordingPrompt = "Must include ⌘, ⌥, or ⌃"
                    return
                }

                let carbonMods = HotkeySetting.carbonModifiers(from: relevantFlags)
                let keyCode = UInt32(event.keyCode)
                let displayStr = HotkeySetting.formatDisplayString(flags: relevantFlags, keyCode: event.keyCode)
                let nameStr = "Custom (\(displayStr))"

                let customSetting = HotkeySetting(
                    id: "custom_\(keyCode)_\(carbonMods)",
                    name: nameStr,
                    keyCode: keyCode,
                    modifiers: carbonMods,
                    displayString: displayStr
                )

                logTrace("Recorded custom shortcut: \(displayStr) (keyCode: \(keyCode), mods: \(carbonMods))")
                GlobalHotKeyManager.shared.updateHotkey(to: customSetting)
                GlobalHotKeyManager.shared.stopRecording(cancelled: false)
                return
            }

            let store = ClipboardHistoryStore.shared
            let count = store.filteredItems.count

            // Check for Cmd + 1..9 shortcuts
            if event.modifierFlags.contains(.command) {
                let numberKeyCodes: [UInt16: Int] = [
                    18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
                ]
                if let targetIdx = numberKeyCodes[event.keyCode], targetIdx < count {
                    let item = store.filteredItems[targetIdx]
                    AppDelegate.shared?.paste(item: item)
                    return
                }
            }

            switch event.keyCode {
            case 53: // Escape
                if store.previewItem != nil {
                    store.previewItem = nil
                    return
                }
                AppDelegate.shared?.hidePanel()
                return

            case 126: // Up Arrow
                if count > 0 {
                    store.selectedIndex = (store.selectedIndex - 1 + count) % count
                    if store.previewItem != nil {
                        store.previewItem = store.filteredItems[store.selectedIndex]
                    }
                }
                return

            case 125: // Down Arrow
                if count > 0 {
                    store.selectedIndex = (store.selectedIndex + 1) % count
                    if store.previewItem != nil {
                        store.previewItem = store.filteredItems[store.selectedIndex]
                    }
                }
                return

            case 36: // Return / Enter
                if !store.isSettingsOpen && count > 0 {
                    let targetItem = store.previewItem ?? (store.selectedIndex < count ? store.filteredItems[store.selectedIndex] : nil)
                    if let item = targetItem {
                        let isShift = event.modifierFlags.contains(.shift)
                        AppDelegate.shared?.paste(item: item, plainText: isShift)
                        return
                    }
                }

            case 49: // Spacebar (Quick Look Preview)
                let isEditingField = (self.firstResponder as? NSTextView)?.isFieldEditor == true
                if isEditingField && !event.modifierFlags.contains(.command) {
                    break
                }
                if !store.isSettingsOpen && count > 0 && store.selectedIndex < count {
                    let currentItem = store.filteredItems[store.selectedIndex]
                    store.togglePreview(for: currentItem)
                    return
                }

            case 16: // Cmd + Y (Quick Look Preview shortcut)
                if event.modifierFlags.contains(.command) && !store.isSettingsOpen && count > 0 && store.selectedIndex < count {
                    let currentItem = store.filteredItems[store.selectedIndex]
                    store.togglePreview(for: currentItem)
                    return
                }

            default:
                break
            }
        }
        super.sendEvent(event)
    }

    public func positionNearMouseOrCenter() {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let currentScreen = screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main

        guard let screen = currentScreen else {
            self.center()
            return
        }

        let screenFrame = screen.visibleFrame
        let panelSize = self.frame.size

        // Position slightly offset from mouse, clamped within visible screen bounds
        var originX = mouseLocation.x - (panelSize.width / 2)
        var originY = mouseLocation.y - (panelSize.height / 2)

        originX = max(screenFrame.minX + 20, min(originX, screenFrame.maxX - panelSize.width - 20))
        originY = max(screenFrame.minY + 20, min(originY, screenFrame.maxY - panelSize.height - 20))

        self.setFrameOrigin(NSPoint(x: originX, y: originY))
    }

    deinit {
        stopClickOutsideMonitor()
    }
}
