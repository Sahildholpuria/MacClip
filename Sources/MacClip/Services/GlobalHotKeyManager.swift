import AppKit
import Carbon

public final class GlobalHotKeyManager {
    public static let shared = GlobalHotKeyManager()

    public var onHotKeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {}

    public func register() {
        // Register Carbon event handler for HotKey event
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                DispatchQueue.main.async {
                    GlobalHotKeyManager.shared.onHotKeyPressed?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        // HotKey: Option + V (⌥ + V)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D434C50), id: 1) // 'MCLP'
        let err = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if err != noErr {
            print("MacClip: Failed to register hotkey Option+V (status: \(err))")
        } else {
            print("MacClip: Global hotkey Option+V successfully registered.")
        }
    }

    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}
