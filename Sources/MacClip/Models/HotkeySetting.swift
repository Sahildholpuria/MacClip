import Foundation
import Carbon
import AppKit

public struct HotkeySetting: Codable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var keyCode: UInt32
    public var modifiers: UInt32
    public var displayString: String

    public init(id: String, name: String, keyCode: UInt32, modifiers: UInt32, displayString: String) {
        self.id = id
        self.name = name
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.displayString = displayString
    }

    public static let optionV = HotkeySetting(
        id: "opt_v",
        name: "Option + V (Default)",
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(optionKey),
        displayString: "⌥V"
    )

    public static let cmdShiftV = HotkeySetting(
        id: "cmd_shift_v",
        name: "Command + Shift + V",
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | shiftKey),
        displayString: "⌘⇧V"
    )

    public static let cmdOptionV = HotkeySetting(
        id: "cmd_opt_v",
        name: "Command + Option + V",
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(cmdKey | optionKey),
        displayString: "⌥⌘V"
    )

    public static let controlV = HotkeySetting(
        id: "ctrl_v",
        name: "Control + V",
        keyCode: UInt32(kVK_ANSI_V),
        modifiers: UInt32(controlKey),
        displayString: "⌃V"
    )

    public static let optionSpace = HotkeySetting(
        id: "opt_space",
        name: "Option + Space",
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(optionKey),
        displayString: "⌥Space"
    )

    public static let presets: [HotkeySetting] = [
        .optionV,
        .cmdShiftV,
        .cmdOptionV,
        .controlV,
        .optionSpace
    ]

    // MARK: - Custom Shortcut Utilities

    public static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        return carbonMods
    }

    public static func formatDisplayString(flags: NSEvent.ModifierFlags, keyCode: UInt16) -> String {
        var str = ""
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        str += stringForKeyCode(keyCode)
        return str
    }

    public static func stringForKeyCode(_ keyCode: UInt16) -> String {
        let specialKeys: [UInt16: String] = [
            UInt16(kVK_Space): "Space",
            UInt16(kVK_Return): "Return",
            UInt16(kVK_Tab): "Tab",
            UInt16(kVK_Delete): "Delete",
            UInt16(kVK_Escape): "Esc",
            123: "←",
            124: "→",
            125: "↓",
            126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4",
            96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        if let special = specialKeys[keyCode] {
            return special
        }

        // Try UCKeyTranslate for layout-accurate character
        if let currentKeyboard = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
           let rawLayoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData) {
            let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
            if let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>?.self) {
                var deadKeyState: UInt32 = 0
                var actualStringLength: Int = 0
                var unicodeChars = [UniChar](repeating: 0, count: 4)

                let status = UCKeyTranslate(
                    keyboardLayout,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    4,
                    &actualStringLength,
                    &unicodeChars
                )

                if status == noErr && actualStringLength > 0 {
                    let str = String(utf16CodeUnits: unicodeChars, count: actualStringLength).uppercased()
                    if !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return str
                    }
                }
            }
        }

        return fallbackKeyString(keyCode)
    }

    private static func fallbackKeyString(_ keyCode: UInt16) -> String {
        let ansiMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
            39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            50: "`"
        ]
        return ansiMap[keyCode] ?? "Key_\(keyCode)"
    }
}
