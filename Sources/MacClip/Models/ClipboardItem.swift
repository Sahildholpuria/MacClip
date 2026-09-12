import Foundation
import AppKit

public struct ClipboardItem: Identifiable, Codable, Equatable {
    public enum ItemType: String, Codable {
        case text
        case image
    }

    public let id: UUID
    public var itemType: ItemType
    public let text: String
    public let timestamp: Date
    public var isPinned: Bool
    public var sourceApp: String?
    public var imagePath: String?
    public var imageWidth: Double?
    public var imageHeight: Double?
    public var imageByteSize: Int?

    public init(
        id: UUID = UUID(),
        itemType: ItemType = .text,
        text: String,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceApp: String? = nil,
        imagePath: String? = nil,
        imageWidth: Double? = nil,
        imageHeight: Double? = nil,
        imageByteSize: Int? = nil
    ) {
        self.id = id
        self.itemType = itemType
        self.text = text
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceApp = sourceApp
        self.imagePath = imagePath
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageByteSize = imageByteSize
    }

    // Custom decoder for backwards-compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.itemType = (try? container.decode(ItemType.self, forKey: .itemType)) ?? .text
        self.text = try container.decode(String.self, forKey: .text)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.isPinned = try container.decode(Bool.self, forKey: .isPinned)
        self.sourceApp = try? container.decode(String.self, forKey: .sourceApp)
        self.imagePath = try? container.decode(String.self, forKey: .imagePath)
        self.imageWidth = try? container.decode(Double.self, forKey: .imageWidth)
        self.imageHeight = try? container.decode(Double.self, forKey: .imageHeight)
        self.imageByteSize = try? container.decode(Int.self, forKey: .imageByteSize)
    }

    public enum ContentCategory: String, Codable {
        case image = "Image"
        case url = "Link"
        case color = "Color"
        case code = "Code"
        case email = "Email"
        case text = "Text"

        public var iconName: String {
            switch self {
            case .image: return "photo.fill"
            case .url: return "link"
            case .color: return "paintpalette.fill"
            case .code: return "curlybraces"
            case .email: return "envelope.fill"
            case .text: return "doc.text"
            }
        }
    }

    public var category: ContentCategory {
        if itemType == .image {
            return .image
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return .url
        }
        if trimmed.count <= 9 && (trimmed.hasPrefix("#") || trimmed.hasPrefix("0x")) {
            let hexRegex = "^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"
            if trimmed.range(of: hexRegex, options: .regularExpression) != nil {
                return .color
            }
        }
        if trimmed.contains("@") && trimmed.contains(".") && !trimmed.contains(" ") {
            return .email
        }
        if trimmed.contains("func ") || trimmed.contains("import ") || trimmed.contains("const ") ||
           trimmed.contains("let ") || trimmed.contains("def ") || trimmed.contains("class ") ||
           (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) ||
           (trimmed.hasPrefix("[") && trimmed.hasSuffix("]")) {
            return .code
        }
        return .text
    }

    public var titlePreview: String {
        if itemType == .image {
            if let w = imageWidth, let h = imageHeight {
                return "Image (\(Int(w)) × \(Int(h)))"
            }
            return "Copied Image"
        }

        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if firstLine.count > 80 {
            return String(firstLine.prefix(80)) + "…"
        }
        return firstLine
    }

    public var formattedDimensions: String? {
        guard let w = imageWidth, let h = imageHeight else { return nil }
        return "\(Int(w)) × \(Int(h))"
    }

    public var formattedFileSize: String? {
        guard let bytes = imageByteSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    public var relativeTimeString: String {
        let seconds = Int(-timestamp.timeIntervalSinceNow)
        if seconds < 10 { return "Just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id && lhs.isPinned == rhs.isPinned && lhs.text == rhs.text && lhs.imagePath == rhs.imagePath
    }
}
