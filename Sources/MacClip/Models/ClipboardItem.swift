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
    public let category: ContentCategory

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
        imageByteSize: Int? = nil,
        category: ContentCategory? = nil
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
        self.category = category ?? ClipboardItem.detectCategory(itemType: itemType, text: text)
    }

    // Custom decoder for backwards-compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let decodedType = (try? container.decode(ItemType.self, forKey: .itemType)) ?? .text
        self.itemType = decodedType
        let decodedText = try container.decode(String.self, forKey: .text)
        self.text = decodedText
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.isPinned = try container.decode(Bool.self, forKey: .isPinned)
        self.sourceApp = try? container.decode(String.self, forKey: .sourceApp)
        self.imagePath = try? container.decode(String.self, forKey: .imagePath)
        self.imageWidth = try? container.decode(Double.self, forKey: .imageWidth)
        self.imageHeight = try? container.decode(Double.self, forKey: .imageHeight)
        self.imageByteSize = try? container.decode(Int.self, forKey: .imageByteSize)
        if let cat = try? container.decode(ContentCategory.self, forKey: .category) {
            self.category = cat
        } else {
            self.category = ClipboardItem.detectCategory(itemType: decodedType, text: decodedText)
        }
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

    public static func detectCategory(itemType: ItemType, text: String) -> ContentCategory {
        if itemType == .image {
            return .image
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return .url
        }
        if trimmed.count <= 10 && (trimmed.hasPrefix("#") || trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X")) {
            let hexRegex = "^(?:#|0x|0X)(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"
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

    // MARK: - Color Formatting Conversions
    public var rgbColorString: String? {
        guard category == .color, let (r, g, b) = parseRGB() else { return nil }
        return "rgb(\(r), \(g), \(b))"
    }

    public var hslColorString: String? {
        guard category == .color, let (r, g, b) = parseRGB() else { return nil }
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0
        let cMax = max(rf, gf, bf)
        let cMin = min(rf, gf, bf)
        let delta = cMax - cMin
        let l = (cMax + cMin) / 2.0

        var h: Double = 0
        var s: Double = 0

        if delta != 0 {
            s = l > 0.5 ? delta / (2.0 - cMax - cMin) : delta / (cMax + cMin)
            if cMax == rf {
                h = ((gf - bf) / delta).truncatingRemainder(dividingBy: 6.0)
            } else if cMax == gf {
                h = ((bf - rf) / delta) + 2.0
            } else {
                h = ((rf - gf) / delta) + 4.0
            }
            h *= 60.0
            if h < 0 { h += 360.0 }
        }

        return "hsl(\(Int(round(h))), \(Int(round(s * 100)))%, \(Int(round(l * 100)))%)"
    }

    private func parseRGB() -> (r: Int, g: Int, b: Int)? {
        var hex = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        else if hex.lowercased().hasPrefix("0x") { hex.removeFirst(2) }

        var intVal: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&intVal) else { return nil }

        switch hex.count {
        case 3: // 12-bit
            return (Int((intVal >> 8) * 17), Int((intVal >> 4 & 0xF) * 17), Int((intVal & 0xF) * 17))
        case 6: // 24-bit
            return (Int(intVal >> 16), Int(intVal >> 8 & 0xFF), Int(intVal & 0xFF))
        case 8: // 32-bit ARGB
            return (Int(intVal >> 16 & 0xFF), Int(intVal >> 8 & 0xFF), Int(intVal & 0xFF))
        default:
            return nil
        }
    }

    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id && lhs.isPinned == rhs.isPinned && lhs.text == rhs.text && lhs.imagePath == rhs.imagePath
    }
}
