import Foundation
import Carbon

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
}
