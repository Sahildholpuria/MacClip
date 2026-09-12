import AppKit

public final class ClipboardMonitor {
    public static let shared = ClipboardMonitor()

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    /// Flag set by PasteManager to prevent capturing its own pasteboard modifications
    public var isSelfPasting = false

    private init() {
        self.lastChangeCount = pasteboard.changeCount
    }

    public func startMonitoring() {
        guard timer == nil else { return }

        // Poll every 0.4 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if isSelfPasting {
            isSelfPasting = false
            return
        }

        // Read text content
        guard let string = pasteboard.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Get frontmost application name (the app from which the user copied)
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        ClipboardHistoryStore.shared.add(text: string, sourceApp: sourceApp)
    }
}
