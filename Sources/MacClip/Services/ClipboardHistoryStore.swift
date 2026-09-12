import Foundation
import AppKit
import Combine

public final class ClipboardHistoryStore: ObservableObject {
    public static let shared = ClipboardHistoryStore()

    @Published public var items: [ClipboardItem] = []
    @Published public var searchText: String = ""
    @Published public var selectedIndex: Int = 0
    @Published public var isSettingsOpen: Bool = false

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

        loadHistory()
    }

    public var filteredItems: [ClipboardItem] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return items
        }
        let query = searchText.lowercased()
        return items.filter { item in
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

        // Skip if identical to top item
        if let first = items.first, first.itemType == .text && first.text == text {
            return
        }

        // Move to top if already existing
        var wasPinned = false
        if let index = items.firstIndex(where: { $0.itemType == .text && $0.text == text }) {
            wasPinned = items[index].isPinned
            items.remove(at: index)
        }

        let newItem = ClipboardItem(
            itemType: .text,
            text: text,
            timestamp: Date(),
            isPinned: wasPinned,
            sourceApp: sourceApp
        )

        items.insert(newItem, at: 0)
        pruneExcessItems()
        selectedIndex = 0
        saveHistory()
    }

    public func addImage(data: Data, dimensions: CGSize, sourceApp: String? = nil) {
        guard !data.isEmpty else { return }

        // Skip if identical to top item
        if let first = items.first, first.itemType == .image,
           first.imageByteSize == data.count,
           first.imageWidth == Double(dimensions.width),
           first.imageHeight == Double(dimensions.height) {
            return
        }

        let id = UUID()
        let fileURL = imagesDirectoryURL.appendingPathComponent("\(id.uuidString).png")

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
            isPinned: false,
            sourceApp: sourceApp,
            imagePath: fileURL.path,
            imageWidth: Double(dimensions.width),
            imageHeight: Double(dimensions.height),
            imageByteSize: data.count
        )

        items.insert(newItem, at: 0)
        pruneExcessItems()
        selectedIndex = 0
        saveHistory()
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
        if let idx = items.firstIndex(where: { $0.id == id }) {
            let item = items.remove(at: idx)
            deleteImageFile(for: item)
        }
        if selectedIndex >= filteredItems.count {
            selectedIndex = max(0, filteredItems.count - 1)
        }
        saveHistory()
    }

    public func togglePin(id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].isPinned.toggle()
            saveHistory()
        }
    }

    public func clearUnpinned() {
        let unpinned = items.filter { !$0.isPinned }
        for item in unpinned {
            deleteImageFile(for: item)
        }
        items.removeAll { !$0.isPinned }
        selectedIndex = 0
        saveHistory()
    }

    public func clearAll() {
        for item in items {
            deleteImageFile(for: item)
        }
        items.removeAll()
        selectedIndex = 0
        saveHistory()
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
