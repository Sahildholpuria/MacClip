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

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkAccessibility()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.checkAccessibility()
        }
    }

    public func paste(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // 1. Write item to pasteboard in all supported formats
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

        // 2. Perform paste simulation
        performPaste()
    }

    private func performPaste() {
        // Delay slightly for panel orderOut to restore key focus to the active application
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            // Method 1: Standard macOS CGEvent paste command via annotated session tap
            let eventSource = CGEventSource(stateID: .combinedSessionState)
            
            if let eventDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 9, keyDown: true),
               let eventUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 9, keyDown: false) {
                
                eventDown.flags = .maskCommand
                eventUp.flags = .maskCommand

                eventDown.post(tap: .cgAnnotatedSessionEventTap)
                eventUp.post(tap: .cgAnnotatedSessionEventTap)
            }

            // Method 2: Also run AppleScript System Events if accessibility is in transition
            if !AXIsProcessTrusted() {
                let scriptSource = "tell application \"System Events\" to keystroke \"v\" using command down"
                if let script = NSAppleScript(source: scriptSource) {
                    var error: NSDictionary?
                    script.executeAndReturnError(&error)
                }
            }
        }
    }
}
