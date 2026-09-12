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

        // Poll every 0.35 seconds for responsive capture
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
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

        // 1. Check for Image content FIRST (screenshots, browser copy, finder image files, preview)
        if let (imgData, dimensions) = extractImage(from: pasteboard) {
            ClipboardHistoryStore.shared.addImage(
                data: imgData,
                dimensions: dimensions,
                sourceApp: sourceApp
            )
            return
        }

        // 2. Check for Text content
        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ClipboardHistoryStore.shared.addText(text: string, sourceApp: sourceApp)
        }
    }

    private func extractImage(from pb: NSPasteboard) -> (data: Data, size: CGSize)? {
        // A. Direct PNG data from pasteboard
        let pngType = NSPasteboard.PasteboardType("public.png")
        if let data = pb.data(forType: pngType),
           let img = NSImage(data: data), img.isValid {
            return (data, img.size)
        }

        // B. Direct TIFF data from pasteboard
        if let data = pb.data(forType: .tiff),
           let img = NSImage(data: data), img.isValid {
            if let pngData = convertToPngData(image: img) {
                return (pngData, img.size)
            }
            return (data, img.size)
        }

        // C. Generic NSImage from pasteboard (catches WebP, JPEG, HEIC, clipboard promises)
        if let img = NSImage(pasteboard: pb), img.isValid {
            if let pngData = convertToPngData(image: img) {
                return (pngData, img.size)
            }
        }

        // D. File URLs (e.g. copied image file in Finder or Desktop)
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            let imageExtensions = ["png", "jpg", "jpeg", "webp", "gif", "tiff", "tif", "heic", "svg", "bmp", "ico"]
            for url in urls {
                if imageExtensions.contains(url.pathExtension.lowercased()),
                   let img = NSImage(contentsOf: url), img.isValid {
                    if let data = try? Data(contentsOf: url) {
                        return (data, img.size)
                    }
                }
            }
        }

        return nil
    }

    private func convertToPngData(image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return rep.representation(using: .png, properties: [:])
    }
}
