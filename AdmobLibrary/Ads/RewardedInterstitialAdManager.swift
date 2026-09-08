//
//  InterstitialAdManager.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 11/10/25.
//

import SwiftUI
@preconcurrency import GoogleMobileAds

// Interstitial Ad Manager
@MainActor
class RewardedInterstitialAdManager: NSObject, FullScreenContentDelegate {
     var rewardedAd: RewardedInterstitialAd?
     var isLoading = false
     var onAdDismissed: (@MainActor @Sendable (Bool) -> Void)?
     var isGranted = false
    
    
    func loadRewardedAdAd(adUnitID: String,
                            onAdLoaded: (@MainActor @Sendable () -> Void)? = nil,
                            onAdFailedToLoad: (@MainActor @Sendable (Error) -> Void)? = nil,
                            onAdDismissed: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        
        guard !isLoading else { return }
        
        if Common.isTestDevice {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            onAdDismissed?(true)
            return
        }
        
        self.isGranted = false
        self.onAdDismissed = onAdDismissed
        isLoading = true
        
        // Hiển thị loading view
        LoadingAdViewController.shared.show()
        
        let request = Request()
        let adID = Common.isDebug
            ? "ca-app-pub-3940256099942544/6978759866"
            : adUnitID
            
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let ad = try await RewardedInterstitialAd.load(with: adID, request: request)
                self.isLoading = false
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.rewardedAd?.paidEventHandler = { [weak self] adValue in
                    Task { @MainActor [weak self] in
                        guard let self, let rewardedAd = self.rewardedAd else { return }
                        PaidEventHandlerManager.shared.getPaidEventHandler(
                            dataPaidEvent: adValue,
                            typeAds: .rewardAds,
                            rewardedInterstitial: rewardedAd,
                            adUnit: adUnitID
                        )
                    }
                }
                print("rewardedInterstitialAd ad loaded successfully")
                onAdLoaded?()
                
                // Auto show interstitial after loaded
                self.showRewardedAdAd()
            } catch {
                self.isLoading = false
                print("Failed to load rewardedInterstitialAd ad: \(error.localizedDescription)")
                // Ẩn loading view khi load thất bại
                LoadingAdViewController.shared.hide()
                onAdFailedToLoad?(error)
            }
        }
    }
    
    func showRewardedAdAd() {
        guard let rewardedAd = rewardedAd else {
            print("rewardedInterstitialAd ad not ready")
            LoadingAdViewController.shared.hide()
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found")
            LoadingAdViewController.shared.hide()
            return
        }
        AdsManager.shared.isShowingAd = true
        rewardedAd.present(from: rootViewController) {
            let reward = rewardedAd.adReward
            print("rewardedInterstitialAd Hehe: \(reward.amount)")
            self.isGranted = true
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present rewardedInterstitialAd ad: \(error.localizedDescription)")
        // Ẩn loading view khi hiển thị quảng cáo thất bại
        LoadingAdViewController.shared.hide()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("rewardedInterstitialAd ad will be presented")
        // Ẩn loading view khi quảng cáo sắp hiển thị
        LoadingAdViewController.shared.hide()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("rewardedInterstitialAd ad dismissed")
        // Load next interstitial ad for future use
        self.rewardedAd = nil
        AdsManager.shared.isShowingAd = false
        // Call the dismiss callback
        onAdDismissed?(self.isGranted)
    }
}

