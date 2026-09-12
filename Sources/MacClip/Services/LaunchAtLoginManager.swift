import Foundation
import ServiceManagement
import Combine

public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()

    @Published public var isEnabled: Bool = false

    private init() {
        checkStatus()
    }

    public func checkStatus() {
        if #available(macOS 13.0, *) {
            self.isEnabled = SMAppService.mainApp.status == .enabled
        }
    }

    public func toggle() {
        setEnabled(!isEnabled)
    }

    public func setEnabled(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                self.isEnabled = SMAppService.mainApp.status == .enabled
                logTrace("LaunchAtLogin status: \(self.isEnabled)")
            } catch {
                logTrace("Failed to set LaunchAtLogin: \(error.localizedDescription)")
                self.isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }
}
