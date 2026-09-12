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
        ClipboardMonitor.shared.isSelfPasting = true

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if item.itemType == .image, let path = item.imagePath,
           let imgData = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let image = NSImage(data: imgData) {
            
            let pItem = NSPasteboardItem()
            if let tiff = image.tiffRepresentation {
                pItem.setData(tiff, forType: .tiff)
                if let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    pItem.setData(png, forType: NSPasteboard.PasteboardType("public.png"))
                }
            } else {
                pItem.setData(imgData, forType: NSPasteboard.PasteboardType("public.png"))
            }
            pasteboard.writeObjects([pItem])
        } else {
            pasteboard.setString(item.text, forType: .string)
        }

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
            print("MacClip: Accessibility permission not granted yet. Item copied to clipboard; manual ⌘V paste works.")
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
