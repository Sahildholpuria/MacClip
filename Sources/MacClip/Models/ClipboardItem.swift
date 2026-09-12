import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let text: String
    public let timestamp: Date
    public var isPinned: Bool
    public var sourceApp: String?

    public init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceApp = sourceApp
    }

    public enum ContentCategory: String, Codable {
        case url = "Link"
        case color = "Color"
        case code = "Code"
        case email = "Email"
        case text = "Text"

        public var iconName: String {
            switch self {
            case .url: return "link"
            case .color: return "paintpalette.fill"
            case .code: return "curlybraces"
            case .email: return "envelope.fill"
            case .text: return "doc.text"
            }
        }
    }

    public var category: ContentCategory {
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
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if firstLine.count > 80 {
            return String(firstLine.prefix(80)) + "…"
        }
        return firstLine
    }

    public var lineCount: Int {
        return text.components(separatedBy: .newlines).count
    }

    public var charCount: Int {
        return text.count
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
        return lhs.id == rhs.id && lhs.isPinned == rhs.isPinned && lhs.text == rhs.text
    }
}
