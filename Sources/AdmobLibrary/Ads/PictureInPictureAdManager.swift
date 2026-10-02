//
//  PictureInPictureAdManager.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 2/10/26.
//

import Foundation
import GoogleMobileAds
import GoogleMobileAds_Private

/// Singleton class that loads, manages lifecycle, and handles events for Picture-in-Picture (PiP)
/// ads.
@MainActor
public class PictureInPictureAdManager: NSObject {

    public static let shared = PictureInPictureAdManager()

    private var pipAd: PictureInPictureAd?
    private let events = PictureInPictureAdEventHandler()

    public var onAdShownListener: (@MainActor () -> Void)?
    public var onAdHiddenListener: (@MainActor () -> Void)?

    private override init() {
        super.init()
        events.owner = self
    }

    /// Loads a Picture-in-Picture ad.
    public func loadAd() async throws {
        let ad = try await PictureInPictureAd.load(
            with: "ca-app-pub-3940256099942544/8810945611",
            request: Request()
        )
        print("Picture-in-Picture ad loaded.")
        pipAd?.hide()
        pipAd = ad
        ad.delegate = events
        ad.paidEventHandler = { value in
            print("Picture-in-Picture ad paid: \(value.value) \(value.currencyCode)")
        }
    }

    /// Shows the Picture-in-Picture ad.
    public func showAd() {
        guard let ad = pipAd else {
            print("No Picture-in-Picture ad available to show.")
            return
        }
        let options = PictureInPictureAdOptions()
        // Uses the Google Mobile Ads SDK's default screen position.
        options.position = .default
        // Binds the ad lifecycle to the host screen.
        options.presentationScope = .screen

        ad.show(with: options)
    }

    /// Hides the currently showing Picture-in-Picture ad.
    public func hideAd() {
        pipAd?.hide()
    }

    /// Destroys the Picture-in-Picture ad and cleans up resources.
    public func destroyAd() {
        pipAd?.hide()
        pipAd = nil
    }

    /// Checks if an ad exists and is available to show.
    public func isAdAvailable() -> Bool {
        return pipAd != nil
    }
}

@MainActor
private final class PictureInPictureAdEventHandler: NSObject, PictureInPictureAdDelegate {
    weak var owner: PictureInPictureAdManager?

    func pictureInPictureAdDidShow(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad shown.")
        owner?.onAdShownListener?()
    }

    func pictureInPictureAdDidHide(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad hidden.")
        owner?.onAdHiddenListener?()
    }

    func pictureInPictureAdDidFailToShow(
        _ pictureInPictureAd: PictureInPictureAd, error: Error
    ) {
        print("Picture-in-Picture ad failed to show: \(error.localizedDescription)")
    }

    func pictureInPictureAdDidRecordImpression(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad recorded an impression.")
    }

    func pictureInPictureAdDidRecordClick(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad recorded a click.")
    }

    func pictureInPictureAdWillPresentScreen(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad will present screen.")
    }

    func pictureInPictureAdWillDismissScreen(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad will dismiss screen.")
    }

    func pictureInPictureAdDidDismissScreen(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad dismissed screen.")
    }
}
