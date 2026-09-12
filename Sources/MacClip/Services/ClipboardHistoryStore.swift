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

    private let maxHistoryCount = 150
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

        loadHistory()
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

    private func pruneExcessItems() {
        if items.count > maxHistoryCount {
            var removeIdx = items.count - 1
            while removeIdx >= 0 && items.count > maxHistoryCount {
                if !items[removeIdx].isPinned {
                    let item = items.remove(at: removeIdx)
                    deleteImageFile(for: item)
                }
                removeIdx -= 1
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
        }
    }

    public func togglePin(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.items.firstIndex(where: { $0.id == id }) {
                self.items[idx].isPinned.toggle()
                self.saveHistory()
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
