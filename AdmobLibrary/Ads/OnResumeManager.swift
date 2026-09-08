//
//  OnResumeManager.swift
//  Mahjong
//
//  Created by Tien Nguyen on 7/4/26.
//


import Foundation
import UIKit
@preconcurrency import GoogleMobileAds

@MainActor
protocol OnResumeManagerDelegate: AnyObject {
    /// Method to be invoked when an app open ad is complete (i.e. dismissed or fails to show).
    func appOpenAdManagerAdDidComplete(_ appOpenAdManager: OnResumeManager)
}

@MainActor
class OnResumeManager: NSObject {
    /// Ad references in the app open beta will time out after four hours,
    /// but this time limit may change in future beta versions. For details, see:
    /// https://support.google.com/admob/answer/9341964?hl=en
    let timeoutInterval: TimeInterval = 4 * 3_600
    /// The app open ad.
    var appOpenAd: AppOpenAd?
    /// Maintains a reference to the delegate.
    weak var appOpenAdManagerDelegate: OnResumeManagerDelegate?
    /// Keeps track of if an app open ad is loading.
    var isLoadingAd = false
    /// Keeps track of if an app open ad is showing.
    var isShowingAd = false
    /// Keeps track of the time when an app open ad was loaded to discard expired ad.
    var loadTime: Date?
    
    var overlayView: UIView?
    
    static let shared = OnResumeManager()
    
    var idAOA = ""
    
    private func wasLoadTimeLessThanNHoursAgo(timeoutInterval: TimeInterval) -> Bool {
        // Check if ad was loaded more than n hours ago.
        if let loadTime = loadTime {
            return Date().timeIntervalSince(loadTime) < timeoutInterval
        }
        return false
    }
    
    private func isAdAvailable() -> Bool {
        // Check if ad exists and can be shown.
        return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInterval: timeoutInterval)
    }
    
    private func appOpenAdManagerAdDidComplete() {
        // The app open ad is considered to be complete when it dismisses or fails to show,
        // call the delegate's appOpenAdManagerAdDidComplete method if the delegate is not nil.
        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
    }
    
    func loadAd(adUnitID: String) {
        // Do not load ad if there is an unused ad or one is already loading.
        
        if Common.isTestDevice {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            return
        }
        
        if isLoadingAd || isAdAvailable() {
            return
        }
        isLoadingAd = true
     
        
        idAOA = Common.isDebug
        ? "ca-app-pub-3940256099942544/5575463023"
        : adUnitID
        
        print("Start loading On resum ad.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let ad = try await AppOpenAd.load(with: self.idAOA, request: Request())
                self.isLoadingAd = false
                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.loadTime = Date()
                print("On resum ad loaded successfully.")
            } catch {
                self.isLoadingAd = false
                self.appOpenAd = nil
                self.loadTime = nil
                print("On resum ad failed to load with error: \(error.localizedDescription).")
            }
        }
    }
    
    func showAdIfAvailable() {
        
        if Common.isTestDevice {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            return
        }
        
        if AdsManager.shared.isShowingAd {
            print("⛔️ Skip AppOpen vì đang có ads khác")
            return
        }
        
        // If the app open ad is already showing, do not show the ad again.
        if isShowingAd {
            print("On resum ad is already showing.")
            return
        }
        // Block ads in test mode
        
        // If the app open ad is not available yet but it is supposed to show,
        // it is considered to be complete in this example. Call the appOpenAdManagerAdDidComplete
        // method and load a new ad.
        if !isAdAvailable() {
            print("On resum ad is not ready yet.")
            appOpenAdManagerAdDidComplete()
            return
        }
        if let ad = appOpenAd {
            print("On resum ad will be displayed.")

            ad.present(from: nil)
            isShowingAd = true
            ad.paidEventHandler = { [weak self] adValue in
                Task { @MainActor [weak self] in
                    guard let self, let appOpenAd = self.appOpenAd else { return }
                    PaidEventHandlerManager.shared.getPaidEventHandler(
                        dataPaidEvent: adValue,
                        typeAds: .aoa,
                        aoa: appOpenAd,
                        adUnit: self.idAOA
                    )
                }
            }
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("No root view controller found")
                return
            }
            
            // Find the topmost presented view controller
            let topViewController = rootViewController
            
            overlayView = UIView(frame: topViewController.view.bounds)
            overlayView?.backgroundColor = UIColor.white
            topViewController.view.addSubview(overlayView!)
        }
    }
}

extension OnResumeManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("On resum ad is will be presented.")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        appOpenAd = nil
        isShowingAd = false
        print("On resum ad was dismissed.")
        appOpenAdManagerAdDidComplete()
        loadAd(adUnitID: idAOA)
    }
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        overlayView?.removeFromSuperview()
    }
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        appOpenAd = nil
        isShowingAd = false
        print("On resum ad failed to present with error: \(error.localizedDescription).")
        overlayView?.removeFromSuperview()
        appOpenAdManagerAdDidComplete()
        loadAd(adUnitID: idAOA)
    }
}


