//
//  LocalizationManager.swift
//  67 - Tap Challenge IOS
//
//  Created by Tien Nguyen on 15/10/25.
//

import Combine
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(
                currentLanguage,
                forKey: "selectedLanguage"
            )
        }
    }

    private init() {
        self.currentLanguage =
            UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
    }

    func localized(_ key: String) -> String {
        return translations[currentLanguage]?[key] ?? translations["en"]?[key]
            ?? key
    }

    private let translations: [String: [String: String]] = [
        "en": [
            "intro.title1": "Wave Your Hand!",
            "intro.desc1": "Your hand becomes the controller. Just move and start having fun.",
            "intro.title2": "Swipe in the Air",
            "intro.desc2": "Navigate quickly with simple gestures. No buttons, no hassle.",
            "intro.title3": "Ready to Control?",
            "intro.desc3": "Experience a magical hands-free way to interact with your device. ✨",
            "intro.next": "Next",
            "language.title": "Select language",
            "language.toast": "Please select languages before apply!",
            "home.ok": "OK",
            "home.play": "Play",
            "home.no_internet": "No Internet Connection",
            "home.cancel": "Cancel",
            "home.no_internet_message":
                "Please check your internet connection and try again.",
            "home.wifi_instruction_title": "Enable Internet Connection",
            "home.wifi_instruction_message":
                "To watch ads, please enable your internet connection:\n\n1. Go to Settings app\n2. Tap WiFi\n3. Turn on WiFi or connect to a network\n\nThen return to this app and try again.",
            "home.ad_failed_title": "Ad Failed to Load",
            "home.ad_failed_message":
                "The ad failed to load. Please try again.",
            "home.try_again": "Try Again",

        ]

    ]
}

// Extension for easy localization
extension String {
    func localized() -> String {
        return LocalizationManager.shared.localized(self)
    }

    func localized(_ args: CVarArg...) -> String {
        let localizedString = LocalizationManager.shared.localized(self)
        return String(format: localizedString, arguments: args)
    }
}
