import AppKit
import SwiftUI

public final class FloatingPanel: NSPanel {
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

        // Auto-dismiss when clicking outside
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )
    }

    @objc private func panelDidResignKey() {
        // Small delay so if user clicked an action inside or activated paste, it processes first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self, self.isVisible else { return }
            self.orderOut(nil)
        }
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return true
    }

    public override func cancelOperation(_ sender: Any?) {
        self.orderOut(nil)
    }

    public override func keyDown(with event: NSEvent) {
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
            self.orderOut(nil)
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
            if count > 0 && store.selectedIndex < count {
                let item = store.filteredItems[store.selectedIndex]
                AppDelegate.shared?.paste(item: item)
            }
            return

        default:
            super.keyDown(with: event)
        }
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
        NotificationCenter.default.removeObserver(self)
    }
}
