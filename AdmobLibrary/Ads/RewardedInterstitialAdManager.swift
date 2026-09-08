//
//  InterstitialAdManager.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 11/10/25.
//

import SwiftUI
import GoogleMobileAds

// Interstitial Ad Manager
class RewardedInterstitialAdManager: NSObject, FullScreenContentDelegate {
     var rewardedAd: RewardedInterstitialAd?
     var isLoading = false
     var onAdDismissed: ((Bool) -> Void)?
     var isGranted = false
    
    
    func loadRewardedAdAd(adUnitID: String,
                            onAdLoaded: (() -> Void)? = nil,
                            onAdFailedToLoad: ((Error) -> Void)? = nil,
                            onAdDismissed: ((Bool) -> Void)? = nil) {
        
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
        RewardedInterstitialAd.load(with: adID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Failed to load rewardedInterstitialAd ad: \(error.localizedDescription)")
                    // Ẩn loading view khi load thất bại
                    LoadingAdViewController.shared.hide()
                    onAdFailedToLoad?(error)
                    return
                }
                
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.rewardedAd?.paidEventHandler = { [weak self] adValue in
                    guard let self, let rewardedAd = self.rewardedAd else { return }
                    PaidEventHandlerManager.shared.getPaidEventHandler(
                        dataPaidEvent: adValue,
                        typeAds: .rewardAds,
                        rewardedInterstitial: rewardedAd,
                        adUnit: adUnitID
                    )
                }
                print("rewardedInterstitialAd ad loaded successfully")
                onAdLoaded?()
                
                // Auto show interstitial after loaded
                self.showRewardedAdAd()
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

