//
//  RatingDialog.swift
//  AdmobLibrary
//

import UIKit

/// In-app rating dialog, with the same flow as the Android `RatingDialog`.
///
/// Stars 1–3 open a feedback sheet and send mail. Stars 4–5 request the system
/// review prompt the first time, then open the App Store write-review page.
///
/// ```swift
/// RatingDialog.Builder()
///     .session(1)
///     .isShowButtonLater(true)
///     .isClickLaterDismiss(true)
///     .setNameApp("My App")
///     .setEmail("support@myapp.com")
///     .setAppStoreID("1234567890")
///     .setOnClickRate { stars in }
///     .setOnClickMaybeLater { }
///     .build()
///     .show()
/// ```
@MainActor
public final class RatingDialog {
    let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Presents the dialog when the session and date rules allow it.
    ///
    /// Returns `false` when those rules suppress it. `ignoreRated(true)` (the default)
    /// still presents the dialog after a previous rating, and `show()` still updates the session counter.
    @discardableResult
    public func show() -> Bool {
        let allowed = RatingDialogStore.sessionAllowsPresentation(
            session: configuration.session,
            dayGap: configuration.dayGap
        )
        let shouldShow = (allowed && !RatingDialogStore.isRated) || configuration.ignoreRated
        guard shouldShow else { return false }
        return RatingDialogPresenter.shared.present(configuration: configuration)
    }

    @MainActor
    public final class Builder {
        private var session = 1
        private var dayGap = 0
        private var ignoreRated = true
        private var showLaterButton = false
        private var dismissOnLater = false
        private var laterButtonTitle = "Maybe Later"
        private var title = "Making things better."
        private var appName = ""
        private var email = ""
        private var appVersion = ""
        private var sdkVersion = ""
        private var deviceName = ""
        private var appStoreID = ""
        private var icon: UIImage?
        private var rateButtonColor = UIColor(red: 1, green: 0.545, blue: 0.290, alpha: 1)
        private var onMaybeLater: (() -> Void)?
        private var onRate: ((Int) -> Void)?

        public init() {}

        /// Sessions required before the dialog can appear.
        /// `1` shows on the first `show()` call. Larger values count calls until they match.
        @discardableResult
        public func session(_ value: Int) -> Builder {
            session = value
            return self
        }

        /// Days after the first launch before the dialog can appear.
        /// Passing `1` allows it on the first day. Values above `0` are stored as `value - 1`.
        @discardableResult
        public func date(_ value: Int) -> Builder {
            dayGap = value > 0 ? value - 1 : value
            return self
        }

        /// When `true` (the default), `show()` presents the dialog even if the user already rated.
        @discardableResult
        public func ignoreRated(_ value: Bool) -> Builder {
            ignoreRated = value
            return self
        }

        @discardableResult
        public func isShowButtonLater(_ value: Bool) -> Builder {
            showLaterButton = value
            return self
        }

        @discardableResult
        public func isClickLaterDismiss(_ value: Bool) -> Builder {
            dismissOnLater = value
            return self
        }

        @discardableResult
        public func setTextButtonLater(_ value: String) -> Builder {
            laterButtonTitle = value
            return self
        }

        @discardableResult
        public func title(_ value: String) -> Builder {
            title = value
            return self
        }

        @discardableResult
        public func setNameApp(_ value: String) -> Builder {
            appName = value
            return self
        }

        @discardableResult
        public func setEmail(_ value: String) -> Builder {
            email = value
            return self
        }

        @discardableResult
        public func setDeviceInfo(appVersion: String, sdkVersion: String, deviceName: String) -> Builder {
            self.appVersion = appVersion
            self.sdkVersion = sdkVersion
            self.deviceName = deviceName
            return self
        }

        /// Numeric App Store id used when a 4–5 star rating opens the write-review page.
        @discardableResult
        public func setAppStoreID(_ value: String) -> Builder {
            appStoreID = value
            return self
        }

        @discardableResult
        public func setIcon(_ image: UIImage?) -> Builder {
            icon = image
            return self
        }

        @discardableResult
        public func ratingButtonColor(_ color: UIColor) -> Builder {
            rateButtonColor = color
            return self
        }

        @discardableResult
        public func setOnClickMaybeLater(_ callback: @escaping () -> Void) -> Builder {
            onMaybeLater = callback
            return self
        }

        @discardableResult
        public func setOnClickRate(_ callback: @escaping (Int) -> Void) -> Builder {
            onRate = callback
            return self
        }

        public func build() -> RatingDialog {
            let resolvedName = appName.isEmpty ? Self.hostAppName() : appName
            let configuration = Configuration(
                session: session,
                dayGap: dayGap,
                ignoreRated: ignoreRated,
                showLaterButton: showLaterButton,
                dismissOnLater: dismissOnLater,
                laterButtonTitle: laterButtonTitle.isEmpty ? "Maybe Later" : laterButtonTitle,
                title: title,
                appName: resolvedName,
                email: email,
                appVersion: appVersion.isEmpty ? Self.hostAppVersion() : appVersion,
                sdkVersion: sdkVersion.isEmpty ? UIDevice.current.systemVersion : sdkVersion,
                deviceName: deviceName.isEmpty ? Self.hardwareModel() : deviceName,
                appStoreID: appStoreID.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon ?? Self.hostAppIcon(),
                rateButtonColor: rateButtonColor,
                onMaybeLater: onMaybeLater,
                onRate: onRate
            )
            return RatingDialog(configuration: configuration)
        }

        private static func hostAppName() -> String {
            let info = Bundle.main.infoDictionary
            let display = info?["CFBundleDisplayName"] as? String
            let bundle = info?["CFBundleName"] as? String
            return display ?? bundle ?? ""
        }

        private static func hostAppVersion() -> String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        }

        private static func hostAppIcon() -> UIImage? {
            guard
                let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                let files = primary["CFBundleIconFiles"] as? [String],
                let name = files.last
            else { return nil }
            return UIImage(named: name)
        }

        private static func hardwareModel() -> String {
            var systemInfo = utsname()
            uname(&systemInfo)
            return withUnsafePointer(to: &systemInfo.machine) { pointer in
                pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(cString: $0)
                }
            }
        }
    }

    struct Configuration {
        var session: Int
        var dayGap: Int
        var ignoreRated: Bool
        var showLaterButton: Bool
        var dismissOnLater: Bool
        var laterButtonTitle: String
        var title: String
        var appName: String
        var email: String
        var appVersion: String
        var sdkVersion: String
        var deviceName: String
        var appStoreID: String
        var icon: UIImage?
        var rateButtonColor: UIColor
        var onMaybeLater: (() -> Void)?
        var onRate: ((Int) -> Void)?
    }
}

enum RatingDialogStore {
    private static let defaults = UserDefaults(suiteName: "RatingDialog") ?? .standard
    private static let sessionCountKey = "session_count"
    private static let rate5Key = "rate_5"
    private static let ratedKey = "rated"
    private static let dateFirstKey = "date_count"
    private static let showNeverKey = "show_never"
    private static let firstRunKey = "firstrun"

    static var isRated: Bool {
        defaults.bool(forKey: ratedKey)
    }

    static func markRated() {
        defaults.set(true, forKey: ratedKey)
    }

    /// First 4–5 star rating uses the in-app review prompt. Later ratings open the App Store.
    static func consumeInAppReviewChance() -> Bool {
        let shouldRequest = defaults.object(forKey: rate5Key) as? Bool ?? true
        if shouldRequest {
            defaults.set(false, forKey: rate5Key)
        }
        return shouldRequest
    }

    static func sessionAllowsPresentation(session: Int, dayGap: Int) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd/yyyy"
        let today = formatter.string(from: Date())

        let isFirstRun = defaults.object(forKey: firstRunKey) as? Bool ?? true
        if isFirstRun {
            defaults.set(false, forKey: firstRunKey)
            defaults.set(today, forKey: dateFirstKey)
        }

        let storedDate = defaults.string(forKey: dateFirstKey) ?? today
        let start = formatter.date(from: storedDate) ?? Date()
        let end = formatter.date(from: today) ?? Date()
        let difference = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0

        if session == 1 {
            return true
        }
        if defaults.bool(forKey: showNeverKey) {
            return false
        }

        let count = defaults.object(forKey: sessionCountKey) as? Int ?? 1
        if session == count && difference >= dayGap {
            defaults.set(1, forKey: sessionCountKey)
            return true
        }
        if session > count {
            defaults.set(count + 1, forKey: sessionCountKey)
            return false
        }
        defaults.set(2, forKey: sessionCountKey)
        return false
    }
}
