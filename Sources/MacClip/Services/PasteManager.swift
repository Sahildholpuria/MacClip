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

        // 1. Write multi-flavor data to pasteboard
        if item.itemType == .image, let path = item.imagePath,
           let imgData = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let image = NSImage(data: imgData) {
            
            ClipboardMonitor.shared.lastSelfPastedImageBytes = imgData.count

            let fileURL = URL(fileURLWithPath: path)
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
            pasteboard.writeObjects([image, fileURL as NSURL])
        } else {
            ClipboardMonitor.shared.lastSelfPastedText = item.text
            pasteboard.setString(item.text, forType: .string)
        }

        // 2. Hide MacClip panel and hide MacClip app to yield focus back to target app
        AppDelegate.shared?.hidePanel()
        NSApp.hide(nil)

        // 3. Explicitly reactivate the target application
        let appToActivate = targetApp ?? NSWorkspace.shared.runningApplications.first {
            $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
        }

        if let app = appToActivate {
            app.activate(options: [.activateIgnoringOtherApps])
        }

        // 4. Delay 200ms for window focus transition, then simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { [weak self] in
            self?.simulatePasteKeystroke(targetApp: appToActivate)
        }
    }

    private func simulatePasteKeystroke(targetApp: NSRunningApplication? = nil) {
        let trusted = AXIsProcessTrusted()

        // 1. Simulate Cmd+V keystroke via CGEvent
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode = CGKeyCode(kVK_ANSI_V) // 9

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand

            // Post directly to target PID if available
            if let pid = targetApp?.processIdentifier {
                keyDown.postToPid(pid)
            }

            // Post to session and HID taps
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
            keyDown.post(tap: .cghidEventTap)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                if let pid = targetApp?.processIdentifier {
                    keyUp.postToPid(pid)
                }
                keyUp.post(tap: .cgAnnotatedSessionEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
        }

        // 2. If accessibility is not granted, notify user so they know item is on clipboard
        if !trusted {
            let notification = NSUserNotification()
            notification.title = "MacClip"
            notification.informativeText = "Copied to clipboard! Press ⌘V to paste."
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
}
