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

    public func paste(item: ClipboardItem, targetApp: NSRunningApplication? = nil) {
        logTrace("PasteManager.paste itemType=\(item.itemType) targetApp=\(targetApp?.localizedName ?? "nil")")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // 1. Write item to pasteboard in all supported formats
        if item.itemType == .image, let path = item.imagePath,
           let imgData = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let image = NSImage(data: imgData) {
            
            ClipboardMonitor.shared.lastSelfPastedImageBytes = imgData.count

            let fileURL = URL(fileURLWithPath: path)
            let pbItem = NSPasteboardItem()

            // Standard PNG flavor (most browsers, chat apps, electron)
            pbItem.setData(imgData, forType: NSPasteboard.PasteboardType("public.png"))

            // TIFF flavor (native Cocoa apps, Keynote, Pages)
            if let tiff = image.tiffRepresentation {
                pbItem.setData(tiff, forType: .tiff)
            }

            // File URL flavor (Finder, file drop targets)
            pbItem.setString(fileURL.absoluteString, forType: NSPasteboard.PasteboardType("public.file-url"))

            pasteboard.writeObjects([pbItem])
            logTrace("Wrote image to pasteboard (PNG + TIFF + fileURL): bytes=\(imgData.count)")
        } else {
            ClipboardMonitor.shared.lastSelfPastedText = item.text
            pasteboard.setString(item.text, forType: .string)
            logTrace("Wrote text to pasteboard: [\(item.text.prefix(30))]")
        }

        // 2. Hide MacClip so target app returns to foreground
        NSApp.hide(nil)

        // 3. Reactivate target application so its focused control receives keystrokes
        if let app = targetApp {
            logTrace("Activating targetApp: \(app.localizedName ?? "") (pid: \(app.processIdentifier))")
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }

        // 4. Perform paste simulation
        performPaste(targetApp: targetApp)
    }

    private func performPaste(targetApp: NSRunningApplication?) {
        // Delay 120ms for target app activation and focus restoration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            logTrace("Executing performPaste simulation")

            if let app = targetApp, !app.isActive {
                if #available(macOS 14.0, *) {
                    app.activate()
                } else {
                    app.activate(options: [.activateIgnoringOtherApps])
                }
            }

            let source = CGEventSource(stateID: .combinedSessionState)
            source?.setLocalEventsFilterDuringSuppressionState(
                [.permitLocalMouseEvents, .permitSystemDefinedEvents],
                state: .eventSuppressionStateSuppressionInterval
            )

            // Add hardware modifier flag (0x000008) so macOS hardware layer recognizes Command key
            let cmdFlag = CGEventFlags(rawValue: UInt64(CGEventFlags.maskCommand.rawValue) | 0x000008)
            let vKeyCode: CGKeyCode = 9 // ANSI 'v'

            guard let eventDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
                  let eventUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
                logTrace("Failed to create CGEvent for paste")
                return
            }

            eventDown.flags = cmdFlag
            eventUp.flags = cmdFlag

            // Post to hardware HID tap
            eventDown.post(tap: .cghidEventTap)
            usleep(25000) // 25ms gap between key down and key up
            eventUp.post(tap: .cghidEventTap)

            logTrace("CGEvent Cmd+V posted to cghidEventTap successfully!")

            // Failsafe: If Accessibility is not trusted, also try System Events keystroke
            if !AXIsProcessTrusted() {
                logTrace("Accessibility not trusted, attempting System Events fallback")
                let scriptSource = "tell application \"System Events\" to keystroke \"v\" using command down"
                if let script = NSAppleScript(source: scriptSource) {
                    var error: NSDictionary?
                    script.executeAndReturnError(&error)
                }
            }
        }
    }
}
