import AppKit
import ApplicationServices
import Carbon

public final class PasteManager {
    public static let shared = PasteManager()

    private init() {}

    public var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    public func requestAccessibility() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public func paste(item: ClipboardItem, targetApp: NSRunningApplication? = nil) {
        ClipboardMonitor.shared.isSelfPasting = true

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)

        // Reactivate previous application
        if let targetApp = targetApp, targetApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp.activate()
        }

        // Give macOS time to switch window focus before issuing Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.simulatePasteKeystroke()
        }
    }

    private func simulatePasteKeystroke() {
        guard AXIsProcessTrusted() else {
            print("MacClip: Accessibility permission not granted. Copied to clipboard, but auto-paste shortcut requires permission.")
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode = CGKeyCode(kVK_ANSI_V) // 9

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = []

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
