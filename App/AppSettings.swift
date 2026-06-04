import CoreGraphics
import Foundation
import ServiceManagement

enum AppSettings {
    private enum Keys {
        static let panelWidth = "panelWidth"
        static let topInset = "topInset"
        static let panelOpen = "panelOpen"
        static let launchAtLogin = "launchAtLogin"
    }

    static let defaultPanelWidth: CGFloat = 340
    static let defaultTopInset: CGFloat = 100

    static var panelWidth: CGFloat {
        get {
            let saved = UserDefaults.standard.double(forKey: Keys.panelWidth)
            return saved > 0 ? CGFloat(saved) : defaultPanelWidth
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: Keys.panelWidth)
        }
    }

    static var topInset: CGFloat {
        get {
            let saved = UserDefaults.standard.double(forKey: Keys.topInset)
            return saved > 0 ? CGFloat(saved) : defaultTopInset
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: Keys.topInset)
        }
    }

    static var panelOpen: Bool {
        get { UserDefaults.standard.object(forKey: Keys.panelOpen) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.panelOpen) }
    }

    static var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.launchAtLogin) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.launchAtLogin) }
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the app as a login item. Returns an error message on failure.
    @discardableResult
    static func applyLaunchAtLogin(_ enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            return nil
        } catch {
            return """
            Could not update login item. Install NotePanel to /Applications, then try again.

            \(error.localizedDescription)
            """
        }
    }
}
