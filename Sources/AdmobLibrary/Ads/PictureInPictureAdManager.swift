//
//  PictureInPictureAdManager.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 2/10/26.
//

import SwiftUI
@preconcurrency import GoogleMobileAds
import GoogleMobileAds_Private

@MainActor
public class PictureInPictureAdManager: NSObject, PictureInPictureAdDelegate {
    public var pictureInPictureAd: PictureInPictureAd?
    public var isLoading = false
    public var onAdDismissed: (@MainActor @Sendable () -> Void)?

    public override init() {
        super.init()
    }

    public func loadPictureInPictureAd(adUnitID: String,
                                        onAdLoaded: (@MainActor @Sendable () -> Void)? = nil,
                                        onAdFailedToLoad: (@MainActor @Sendable (Error) -> Void)? = nil,
                                        onAdDismissed: (@MainActor @Sendable () -> Void)? = nil) {

        guard !isLoading else { return }

        self.onAdDismissed = onAdDismissed

        if Common.isTestDevice {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            onAdDismissed?()
            return
        }

        isLoading = true

        // LoadingAdViewController.shared.show()

        let request = Request()
        let adID = Common.isDebug
            ? "ca-app-pub-3940256099942544/8810945611"
            : adUnitID

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let ad = try await PictureInPictureAd.load(with: adID, request: request)
                self.isLoading = false
                self.pictureInPictureAd?.hide()
                self.pictureInPictureAd = ad
                self.pictureInPictureAd?.delegate = self
                self.pictureInPictureAd?.paidEventHandler = { [weak self] adValue in
                    Task { @MainActor [weak self] in
                        guard let self, let pictureInPictureAd = self.pictureInPictureAd else { return }
                        PaidEventHandlerManager.shared.getPaidEventHandler(
                            dataPaidEvent: adValue,
                            typeAds: .pipAds,
                            pip: pictureInPictureAd,
                            adUnit: adUnitID
                        )
                    }
                }
                print("Picture-in-Picture ad loaded successfully")
                onAdLoaded?()

                self.showPictureInPictureAd()
            } catch {
                self.isLoading = false
                print("Failed to load Picture-in-Picture ad: \(error.localizedDescription)")
                LoadingAdViewController.shared.hide()
                onAdFailedToLoad?(error)
            }
        }
    }

    public func showPictureInPictureAd() {
        guard let pictureInPictureAd = pictureInPictureAd else {
            print("Picture-in-Picture ad not ready")
            LoadingAdViewController.shared.hide()
            return
        }

        let options = PictureInPictureAdOptions()
        options.position = .default
        options.presentationScope = .screen

        AdsManager.shared.isShowingAd = true
        pictureInPictureAd.show(with: options)
    }

    public func hidePictureInPictureAd() {
        pictureInPictureAd?.hide()
    }

    public func pictureInPictureAdDidShow(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad shown")
        LoadingAdViewController.shared.hide()
    }

    public func pictureInPictureAdDidHide(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad hidden")
        self.pictureInPictureAd = nil
        AdsManager.shared.isShowingAd = false
        onAdDismissed?()
    }

    public func pictureInPictureAdDidFailToShow(_ pictureInPictureAd: PictureInPictureAd, error: Error) {
        print("Failed to present Picture-in-Picture ad: \(error.localizedDescription)")
        LoadingAdViewController.shared.hide()
        AdsManager.shared.isShowingAd = false
        onAdDismissed?()
    }

    public func pictureInPictureAdDidRecordImpression(_ pictureInPictureAd: PictureInPictureAd) {
    }

    public func pictureInPictureAdWillPresentScreen(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad will present screen")
        AdsManager.shared.isShowingAd = true
    }

    public func pictureInPictureAdDidDismissScreen(_ pictureInPictureAd: PictureInPictureAd) {
        print("Picture-in-Picture ad dismissed screen")
        AdsManager.shared.isShowingAd = self.pictureInPictureAd != nil
    }
}
