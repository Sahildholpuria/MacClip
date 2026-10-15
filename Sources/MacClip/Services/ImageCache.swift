import AppKit

public final class ImageCache {
    public static let shared = ImageCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 120
        cache.totalCostLimit = 80 * 1024 * 1024 // 80 MB memory limit
    }

    public func image(for path: String) -> NSImage? {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let loaded = NSImage(contentsOfFile: path), loaded.isValid else {
            return nil
        }

        let cost = Int(loaded.size.width * loaded.size.height * 4)
        cache.setObject(loaded, forKey: key, cost: cost)
        return loaded
    }

    public func removeImage(for path: String) {
        cache.removeObject(forKey: path as NSString)
    }

    public func clear() {
        cache.removeAllObjects()
    }
}
