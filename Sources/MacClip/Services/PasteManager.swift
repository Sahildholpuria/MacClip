import AppKit
import ApplicationServices
import Carbon
import Combine

public final class PasteManager: ObservableObject {
    public static let shared = PasteManager()

    @Published public var isAccessibilityGranted: Bool = false
    @Published public var isBannerDismissed: Bool = false

    private let userDefaultsDismissKey = "MacClip_AccessibilityBannerDismissed_v2"

    private init() {
        self.isBannerDismissed = UserDefaults.standard.bool(forKey: userDefaultsDismissKey)
        self.isAccessibilityGranted = AXIsProcessTrusted()
    }

    public func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isAccessibilityGranted = trusted
        }
    }

    public func dismissBanner() {
        isBannerDismissed = true
        UserDefaults.standard.set(true, forKey: userDefaultsDismissKey)
    }

    public func resetBannerDismissed() {
        isBannerDismissed = false
        UserDefaults.standard.set(false, forKey: userDefaultsDismissKey)
    }

    public func requestAccessibility() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // Open macOS System Settings directly to Privacy & Security -> Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        // Recheck status after brief delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkAccessibility()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.checkAccessibility()
        }
    }

    public func paste(item: ClipboardItem, targetApp: NSRunningApplication? = nil) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // 1. Populate pasteboard with comprehensive formats
        if item.itemType == .image, let path = item.imagePath,
           let imgData = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let image = NSImage(data: imgData) {
            
            ClipboardMonitor.shared.lastSelfPastedImageBytes = imgData.count

            let fileURL = URL(fileURLWithPath: path)
            
            // Declare all standard image types
            pasteboard.declareTypes([
                .tiff,
                NSPasteboard.PasteboardType("public.png"),
                NSPasteboard.PasteboardType("public.file-url")
            ], owner: nil)

            if let tiff = image.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }
            pasteboard.setData(imgData, forType: NSPasteboard.PasteboardType("public.png"))
            pasteboard.setString(fileURL.absoluteString, forType: NSPasteboard.PasteboardType("public.file-url"))
            
            // Write both NSImage and NSURL objects for maximum compatibility across Slack, Discord, Pages, Notes, etc.
            pasteboard.writeObjects([image, fileURL as NSURL])
        } else {
            ClipboardMonitor.shared.lastSelfPastedText = item.text
            pasteboard.setString(item.text, forType: .string)
        }

        // 2. Hide MacClip panel and process so macOS automatically yields focus back to the target app
        DispatchQueue.main.async {
            AppDelegate.shared?.hidePanel()
            NSApp.hide(nil)

            // Explicitly reactivate the target application
            if let targetApp = targetApp, targetApp.bundleIdentifier != Bundle.main.bundleIdentifier {
                targetApp.activate(options: [.activateIgnoringOtherApps])
            }

            // 3. Simulate Cmd+V keystroke after focus transition settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                self.simulatePasteKeystroke()
            }
        }
    }

    private func simulatePasteKeystroke() {
        guard AXIsProcessTrusted() else {
            print("MacClip: Accessibility permission not granted yet. Item copied to clipboard for manual ⌘V paste.")
            return
        }

        // Use hidSystemState so physical modifier keys (like Option) don't contaminate the synthetic event
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode = CGKeyCode(kVK_ANSI_V) // 9

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        // Both down and up events must have Command modifier flag
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyDown.post(tap: .cgAnnotatedSessionEventTap)

        // Ensure a 25ms gap between key-down and key-up for responsive event-loop consumption
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
            keyUp.post(tap: .cghidEventTap)
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
