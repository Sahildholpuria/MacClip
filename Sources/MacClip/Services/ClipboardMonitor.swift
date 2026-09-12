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

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        // 1. Check for Image content first
        let pngType = NSPasteboard.PasteboardType("public.png")
        let tiffType = NSPasteboard.PasteboardType.tiff

        if let pngData = pasteboard.data(forType: pngType) ?? pasteboard.data(forType: tiffType),
           let image = NSImage(data: pngData) {
            // Convert to clean PNG representation
            let finalData: Data?
            if let tiffRep = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffRep) {
                finalData = bitmap.representation(using: .png, properties: [:])
            } else {
                finalData = pngData
            }

            if let validData = finalData {
                ClipboardHistoryStore.shared.addImage(
                    data: validData,
                    dimensions: image.size,
                    sourceApp: sourceApp
                )
                return
            }
        }

        // 2. Check for Text content
        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ClipboardHistoryStore.shared.addText(text: string, sourceApp: sourceApp)
        }
    }
}
