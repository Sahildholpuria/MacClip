import Foundation
import AppKit
import Combine

public final class ClipboardHistoryStore: ObservableObject {
    public static let shared = ClipboardHistoryStore()

    @Published public var items: [ClipboardItem] = []
    @Published public var searchText: String = "" {
        didSet {
            selectedIndex = 0
        }
    }
    public enum FilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case pinned = "Pinned"
        case text = "Text"
        case images = "Images"
        case links = "Links"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .all: return "square.stack.3d.up.fill"
            case .pinned: return "pin.fill"
            case .text: return "text.alignleft"
            case .images: return "photo.fill"
            case .links: return "link"
            }
        }
    }

    @Published public var selectedCategory: FilterCategory = .all {
        didSet {
            selectedIndex = 0
        }
    }
    @Published public var selectedIndex: Int = 0
    @Published public var hoveredIndex: Int? = nil
    @Published public var isSettingsOpen: Bool = false
    @Published public var previewItem: ClipboardItem? = nil
    @Published public var ignorePasswordManagers: Bool = true {
        didSet {
            UserDefaults.standard.set(ignorePasswordManagers, forKey: "MacClip_IgnorePasswordManagers")
        }
    }

    public enum HistoryLimit: Int, CaseIterable, Identifiable {
        case fifty = 50
        case oneHundred = 100
        case twoHundredFifty = 250
        case fiveHundred = 500
        case unlimited = 10000

        public var id: Int { rawValue }

        public var label: String {
            switch self {
            case .fifty: return "50"
            case .oneHundred: return "100"
            case .twoHundredFifty: return "250"
            case .fiveHundred: return "500"
            case .unlimited: return "Unlimited"
            }
        }
    }

    public enum RetentionPeriod: Int, CaseIterable, Identifiable {
        case never = 0
        case oneDay = 1
        case sevenDays = 7
        case thirtyDays = 30

        public var id: Int { rawValue }

        public var label: String {
            switch self {
            case .never: return "Never"
            case .oneDay: return "24h"
            case .sevenDays: return "7 Days"
            case .thirtyDays: return "30 Days"
            }
        }
    }

    @Published public var maxHistoryLimit: HistoryLimit = .oneHundred {
        didSet {
            UserDefaults.standard.set(maxHistoryLimit.rawValue, forKey: "MacClip_MaxHistoryLimit")
            pruneExcessItems()
            saveHistory()
            updateStorageStats()
        }
    }

    @Published public var retentionPeriod: RetentionPeriod = .never {
        didSet {
            UserDefaults.standard.set(retentionPeriod.rawValue, forKey: "MacClip_RetentionPeriodDays")
            _ = performAutoCleanup()
        }
    }

    @Published public var storageInfoText: String = "Calculating..."
    @Published public var lastCleanupMessage: String? = nil

    private var cleanupTimer: Timer?
    private let storageURL: URL
    public let imagesDirectoryURL: URL

    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MacClip", isDirectory: true)
        let imgDir = appDir.appendingPathComponent("Images", isDirectory: true)

        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imgDir, withIntermediateDirectories: true)

        self.storageURL = appDir.appendingPathComponent("history.json")
        self.imagesDirectoryURL = imgDir

        if UserDefaults.standard.object(forKey: "MacClip_IgnorePasswordManagers") != nil {
            self.ignorePasswordManagers = UserDefaults.standard.bool(forKey: "MacClip_IgnorePasswordManagers")
        } else {
            self.ignorePasswordManagers = true
        }

        if let storedLimitVal = UserDefaults.standard.object(forKey: "MacClip_MaxHistoryLimit") as? Int,
           let limit = HistoryLimit(rawValue: storedLimitVal) {
            self.maxHistoryLimit = limit
        } else {
            self.maxHistoryLimit = .oneHundred
        }

        if let storedRetVal = UserDefaults.standard.object(forKey: "MacClip_RetentionPeriodDays") as? Int,
           let ret = RetentionPeriod(rawValue: storedRetVal) {
            self.retentionPeriod = ret
        } else {
            self.retentionPeriod = .never
        }

        loadHistory()
        _ = performAutoCleanup()
        updateStorageStats()

        // Periodic auto-cleanup every 1 hour
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.performAutoCleanup()
        }
        if let timer = cleanupTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    public func togglePreview(for item: ClipboardItem?) {
        if let item = item, previewItem?.id == item.id {
            previewItem = nil
        } else {
            previewItem = item
        }
    }

    public func closePreview() {
        previewItem = nil
    }

    public func count(for category: FilterCategory) -> Int {
        switch category {
        case .all: return items.count
        case .pinned: return items.filter { $0.isPinned }.count
        case .text: return items.filter { $0.itemType == .text && $0.category != .url }.count
        case .images: return items.filter { $0.itemType == .image }.count
        case .links: return items.filter { $0.category == .url }.count
        }
    }

    public var filteredItems: [ClipboardItem] {
        var base = items
        switch selectedCategory {
        case .all:
            break
        case .pinned:
            base = base.filter { $0.isPinned }
        case .text:
            base = base.filter { $0.itemType == .text && $0.category != .url }
        case .images:
            base = base.filter { $0.itemType == .image }
        case .links:
            base = base.filter { $0.category == .url }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return base
        }
        return base.filter { item in
            if item.text.lowercased().contains(query) { return true }
            if let source = item.sourceApp, source.lowercased().contains(query) { return true }
            if item.category.rawValue.lowercased().contains(query) { return true }
            if item.itemType == .image && ("image".contains(query) || "photo".contains(query) || "screenshot".contains(query)) {
                return true
            }
            return false
        }
    }

    public func addText(text: String, sourceApp: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Skip if identical to top item
            if let first = self.items.first, first.itemType == .text && first.text == text {
                return
            }

            // Move to top if already existing
            var wasPinned = false
            if let index = self.items.firstIndex(where: { $0.itemType == .text && $0.text == text }) {
                wasPinned = self.items[index].isPinned
                self.items.remove(at: index)
            }

            let newItem = ClipboardItem(
                itemType: .text,
                text: text,
                timestamp: Date(),
                isPinned: wasPinned,
                sourceApp: sourceApp
            )

            self.objectWillChange.send()
            self.items.insert(newItem, at: 0)
            self.pruneExcessItems()
            self.selectedIndex = 0
            self.saveHistory()
        }
    }

    public func addImage(data: Data, dimensions: CGSize, sourceApp: String? = nil) {
        guard !data.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Skip if identical to top item
            if let first = self.items.first, first.itemType == .image,
               first.imageByteSize == data.count,
               first.imageWidth == Double(dimensions.width),
               first.imageHeight == Double(dimensions.height) {
                return
            }

            var wasPinned = false
            if let index = self.items.firstIndex(where: { $0.itemType == .image && $0.imageByteSize == data.count && $0.imageWidth == Double(dimensions.width) && $0.imageHeight == Double(dimensions.height) }) {
                wasPinned = self.items[index].isPinned
                let oldItem = self.items.remove(at: index)
                self.deleteImageFile(for: oldItem)
            }

            let id = UUID()
            let fileURL = self.imagesDirectoryURL.appendingPathComponent("\(id.uuidString).png")

            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("MacClip: Failed to write image to disk: \(error)")
                return
            }

            let title = "Image (\(Int(dimensions.width)) × \(Int(dimensions.height)))"
            let newItem = ClipboardItem(
                id: id,
                itemType: .image,
                text: title,
                timestamp: Date(),
                isPinned: wasPinned,
                sourceApp: sourceApp,
                imagePath: fileURL.path,
                imageWidth: Double(dimensions.width),
                imageHeight: Double(dimensions.height),
                imageByteSize: data.count
            )

            self.objectWillChange.send()
            self.items.insert(newItem, at: 0)
            self.pruneExcessItems()
            self.selectedIndex = 0
            self.saveHistory()
        }
    }

    public func pruneExcessItems() {
        let maxLimit = maxHistoryLimit.rawValue
        if items.count > maxLimit {
            var removeIdx = items.count - 1
            while removeIdx >= 0 && items.count > maxLimit {
                if !items[removeIdx].isPinned {
                    let item = items.remove(at: removeIdx)
                    deleteImageFile(for: item)
                }
                removeIdx -= 1
            }
        }
    }

    @discardableResult
    public func performAutoCleanup() -> (prunedCount: Int, freedBytes: Int64) {
        var pruned = 0
        var freed: Int64 = 0

        // 1. Age-based cleanup for unpinned items
        if retentionPeriod != .never {
            let now = Date()
            let cutoffDays = retentionPeriod.rawValue
            if let cutoffDate = Calendar.current.date(byAdding: .day, value: -cutoffDays, to: now) {
                var idx = items.count - 1
                while idx >= 0 {
                    let item = items[idx]
                    if !item.isPinned && item.timestamp < cutoffDate {
                        if item.itemType == .image, let path = item.imagePath {
                            if let attr = try? FileManager.default.attributesOfItem(atPath: path),
                               let size = attr[.size] as? Int64 {
                                freed += size
                            }
                        }
                        let removed = items.remove(at: idx)
                        deleteImageFile(for: removed)
                        pruned += 1
                    }
                    idx -= 1
                }
            }
        }

        // 2. Count-based pruning
        let limit = maxHistoryLimit.rawValue
        if items.count > limit {
            var idx = items.count - 1
            while idx >= 0 && items.count > limit {
                let item = items[idx]
                if !item.isPinned {
                    if item.itemType == .image, let path = item.imagePath {
                        if let attr = try? FileManager.default.attributesOfItem(atPath: path),
                           let size = attr[.size] as? Int64 {
                            freed += size
                        }
                    }
                    let removed = items.remove(at: idx)
                    deleteImageFile(for: removed)
                    pruned += 1
                }
                idx -= 1
            }
        }

        if pruned > 0 {
            self.objectWillChange.send()
            if selectedIndex >= filteredItems.count {
                selectedIndex = max(0, filteredItems.count - 1)
            }
            saveHistory()
        }

        updateStorageStats()

        let freedFormatted = ByteCountFormatter.string(fromByteCount: freed, countStyle: .file)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if pruned > 0 {
                self.lastCleanupMessage = "Pruned \(pruned) item\(pruned == 1 ? "" : "s") (freed \(freedFormatted))"
            } else {
                self.lastCleanupMessage = "History is clean. Nothing to prune."
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                if self?.lastCleanupMessage != nil {
                    self?.lastCleanupMessage = nil
                }
            }
        }

        return (pruned, freed)
    }

    public func updateStorageStats() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            var totalBytes: Int64 = 0

            if let histAttr = try? FileManager.default.attributesOfItem(atPath: self.storageURL.path),
               let size = histAttr[.size] as? Int64 {
                totalBytes += size
            }

            if let files = try? FileManager.default.contentsOfDirectory(atPath: self.imagesDirectoryURL.path) {
                for file in files {
                    let path = self.imagesDirectoryURL.appendingPathComponent(file).path
                    if let attr = try? FileManager.default.attributesOfItem(atPath: path),
                       let size = attr[.size] as? Int64 {
                        totalBytes += size
                    }
                }
            }

            let sizeFormatted = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            let itemCount = self.items.count
            let pinnedCount = self.items.filter { $0.isPinned }.count

            let text = "\(itemCount) item\(itemCount == 1 ? "" : "s") (\(pinnedCount) pinned) • \(sizeFormatted)"
            DispatchQueue.main.async {
                self.storageInfoText = text
            }
        }
    }

    public func delete(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.items.firstIndex(where: { $0.id == id }) {
                let item = self.items.remove(at: idx)
                self.deleteImageFile(for: item)
            }
            if self.selectedIndex >= self.filteredItems.count {
                self.selectedIndex = max(0, self.filteredItems.count - 1)
            }
            self.saveHistory()
            self.updateStorageStats()
        }
    }

    public func togglePin(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.items.firstIndex(where: { $0.id == id }) {
                self.items[idx].isPinned.toggle()
                self.saveHistory()
                self.updateStorageStats()
            }
        }
    }

    public func clearUnpinned() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let unpinned = self.items.filter { !$0.isPinned }
            for item in unpinned {
                self.deleteImageFile(for: item)
            }
            self.items.removeAll { !$0.isPinned }
            self.selectedIndex = 0
            self.saveHistory()
            self.updateStorageStats()
        }
    }

    public func clearAll() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for item in self.items {
                self.deleteImageFile(for: item)
            }
            self.items.removeAll()
            self.selectedIndex = 0
            self.saveHistory()
            self.updateStorageStats()
        }
    }

    private func deleteImageFile(for item: ClipboardItem) {
        if item.itemType == .image, let path = item.imagePath {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    private func saveHistory() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(self.items)
                try data.write(to: self.storageURL, options: .atomic)
            } catch {
                print("Error saving history: \(error)")
            }
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            self.items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Error loading history: \(error)")
        }
    }
}
