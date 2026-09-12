import AppKit
import Carbon
import Combine

public final class GlobalHotKeyManager: ObservableObject {
    public static let shared = GlobalHotKeyManager()

    public var onHotKeyPressed: (() -> Void)?

    @Published public var currentSetting: HotkeySetting

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let userDefaultsKey = "MacClip_CustomHotkey"

    private init() {
        // Load saved setting or default to Option + V
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(HotkeySetting.self, from: data) {
            self.currentSetting = saved
        } else {
            self.currentSetting = .optionV
        }
    }

    public func register() {
        unregister()

        // Register Carbon event handler for HotKey event if not already done
        if eventHandlerRef == nil {
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
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4D434C50), id: 1) // 'MCLP'
        let err = RegisterEventHotKey(
            currentSetting.keyCode,
            currentSetting.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if err != noErr {
            print("MacClip: Failed to register hotkey \(currentSetting.displayString) (status: \(err))")
        } else {
            print("MacClip: Hotkey \(currentSetting.displayString) successfully registered.")
        }
    }

    public func updateHotkey(to newSetting: HotkeySetting) {
        currentSetting = newSetting
        if let data = try? JSONEncoder().encode(newSetting) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        register()
    }

    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    deinit {
        unregister()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}
