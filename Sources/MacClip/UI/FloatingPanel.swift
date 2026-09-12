import AppKit
import SwiftUI

public final class FloatingPanel: NSPanel {
    private var clickOutsideMonitor: Any?

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
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
        if event.type == .keyDown {
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
                AppDelegate.shared?.hidePanel()
                return

            case 126: // Up Arrow
                if count > 0 {
                    store.selectedIndex = (store.selectedIndex - 1 + count) % count
                }
                return

            case 125: // Down Arrow
                if count > 0 {
                    store.selectedIndex = (store.selectedIndex + 1) % count
                }
                return

            case 36: // Return / Enter
                if !store.isSettingsOpen && count > 0 && store.selectedIndex < count {
                    let item = store.filteredItems[store.selectedIndex]
                    AppDelegate.shared?.paste(item: item)
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
