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
class InterstitialAdManager: NSObject, FullScreenContentDelegate {
     var interstitialAd: InterstitialAd?
     var isLoading = false
     var onAdDismissed: (@MainActor @Sendable () -> Void)?
    
    func loadInterstitialAd(adUnitID: String, 
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
        
        // Hiển thị loading view
        LoadingAdViewController.shared.show()
        
        let request = Request()
        let adID = Common.isDebug
            ? "ca-app-pub-3940256099942544/4411468910"
            : adUnitID
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let ad = try await InterstitialAd.load(with: adID, request: request)
                self.isLoading = false
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                self.interstitialAd?.paidEventHandler = { [weak self] adValue in
                    Task { @MainActor [weak self] in
                        guard let self, let interstitialAd = self.interstitialAd else { return }
                        PaidEventHandlerManager.shared.getPaidEventHandler(
                            dataPaidEvent: adValue,
                            typeAds: .interAds,
                            inter: interstitialAd,
                            adUnit: adUnitID
                        )
                    }
                }
                print("Interstitial ad loaded successfully")
                onAdLoaded?()
                
                // Auto show interstitial after loaded
                self.showInterstitialAd()
            } catch {
                self.isLoading = false
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                // Ẩn loading view khi load thất bại
                LoadingAdViewController.shared.hide()
                onAdFailedToLoad?(error)
            }
        }
    }
    
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd else {
            print("Interstitial ad not ready")
            LoadingAdViewController.shared.hide()
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No root view controller found")
            LoadingAdViewController.shared.hide()
            return
        }
        
        // Find the topmost presented view controller
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        // Only present if no view controller is currently being presented
        guard topViewController.presentedViewController == nil else {
            print("Cannot present interstitial ad: A view controller is already being presented")
            LoadingAdViewController.shared.hide()
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showInterstitialAd()
            }
            return
        }
        
        AdsManager.shared.isShowingAd = true
        
        interstitialAd.present(from: topViewController)
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad: \(error.localizedDescription)")
        // Ẩn loading view khi hiển thị quảng cáo thất bại
        LoadingAdViewController.shared.hide()
        // Call dismiss callback if presentation fails
        AdsManager.shared.isShowingAd = false
        onAdDismissed?()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad will be presented")
        // Ẩn loading view khi quảng cáo sắp hiển thị
        LoadingAdViewController.shared.hide()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad dismissed")
        // Load next interstitial ad for future use
        self.interstitialAd = nil
        AdsManager.shared.isShowingAd = false
        // Call the dismiss callback
        onAdDismissed?()
    }
    
    func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
    }
}

