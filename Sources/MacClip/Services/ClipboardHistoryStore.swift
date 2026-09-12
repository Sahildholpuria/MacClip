import Foundation
import Combine

public final class ClipboardHistoryStore: ObservableObject {
    public static let shared = ClipboardHistoryStore()

    @Published public var items: [ClipboardItem] = []
    @Published public var searchText: String = ""
    @Published public var selectedIndex: Int = 0

    private let maxHistoryCount = 150
    private let storageURL: URL

    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MacClip", isDirectory: true)

        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.storageURL = appDir.appendingPathComponent("history.json")

        loadHistory()
    }

    public var filteredItems: [ClipboardItem] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return items
        }
        let query = searchText.lowercased()
        return items.filter { item in
            item.text.lowercased().contains(query) ||
            (item.sourceApp?.lowercased().contains(query) ?? false) ||
            item.category.rawValue.lowercased().contains(query)
        }
    }

    public func add(text: String, sourceApp: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // If identical to the most recent item, do not duplicate
        if let first = items.first, first.text == text {
            return
        }

        // If existing anywhere in list, remove it so it moves to top (unless pinned, then keep pinned flag)
        var wasPinned = false
        if let index = items.firstIndex(where: { $0.text == text }) {
            wasPinned = items[index].isPinned
            items.remove(at: index)
        }

        let newItem = ClipboardItem(
            text: text,
            timestamp: Date(),
            isPinned: wasPinned,
            sourceApp: sourceApp
        )

        // Insert at beginning
        items.insert(newItem, at: 0)

        // Limit size, retaining pinned items
        if items.count > maxHistoryCount {
            var removeIdx = items.count - 1
            while removeIdx >= 0 && items.count > maxHistoryCount {
                if !items[removeIdx].isPinned {
                    items.remove(at: removeIdx)
                }
                removeIdx -= 1
            }
        }

        selectedIndex = 0
        saveHistory()
    }

    public func delete(id: UUID) {
        items.removeAll { $0.id == id }
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
        items.removeAll { !$0.isPinned }
        selectedIndex = 0
        saveHistory()
    }

    public func clearAll() {
        items.removeAll()
        selectedIndex = 0
        saveHistory()
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
