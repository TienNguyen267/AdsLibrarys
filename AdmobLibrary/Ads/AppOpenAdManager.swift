//
//  Copyright 2021 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@preconcurrency import GoogleMobileAds

@MainActor
// [START app_open_ad_manager_delegate]
protocol AppOpenAdManagerDelegate: AnyObject {
    /// Method to be invoked when an app open ad life cycle is complete (i.e. dismissed or fails to
    /// show).
    func appOpenAdManagerAdDidComplete(_ appOpenAdManager: AppOpenAdManager)
}
// [END app_open_ad_manager_delegate]

@MainActor
// [START app_open_ad_manager]
class AppOpenAdManager: NSObject {
    /// The app open ad.
    var appOpenAd: AppOpenAd?
    /// Maintains a reference to the delegate.
    weak var appOpenAdManagerDelegate: AppOpenAdManagerDelegate?
    /// Keeps track of if an app open ad is loading.
    var isLoadingAd = false
    /// Keeps track of if an app open ad is showing.
    var isShowingAd = false
    /// Keeps track of the time when an app open ad was loaded to discard expired ad.
    var loadTime: Date?
    /// For more interval details, see https://support.google.com/admob/answer/9341964
    let timeoutInterval: TimeInterval = 4 * 3_600
    var overlayView: UIView?
    var onAdDismissed: (() -> Void)?
    
    static let shared = AppOpenAdManager()
    // [END app_open_ad_manager]
    
    // [START ad_expiration]
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
    // [END ad_expiration]
    
    // [START load_ad]
    func loadAOA(adUnitID: String,
                onAdDismissed: (() -> Void)? = nil) async {
        // Do not load ad if there is an unused ad or one is already loading.
        
        self.onAdDismissed = onAdDismissed
        
        if Common.isTestDevice {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            onAdDismissed?()
            return
        }
        
        if isLoadingAd || isAdAvailable() {
            return
        }
        isLoadingAd = true
        
        let adID = Common.isDebug
        ? "ca-app-pub-3940256099942544/5575463023"
        : adUnitID
        
        do {
            appOpenAd = try await AppOpenAd.load(with: adID, request: Request())
            // [START set_delegate]
            appOpenAd?.fullScreenContentDelegate = self
            appOpenAd?.paidEventHandler = { [weak self] adValue in
                guard let self, let appOpenAd = self.appOpenAd else { return }
                PaidEventHandlerManager.shared.getPaidEventHandler(
                    dataPaidEvent: adValue,
                    typeAds: .aoa,
                    aoa: appOpenAd,
                    adUnit: adUnitID
                )
            }
            // [END set_delegate]
            loadTime = Date()
            
            DispatchQueue.main.async {
                self.showAdIfAvailable()
            }
        } catch {
            print("App open ad failed to load with error: \(error.localizedDescription)")
            appOpenAd = nil
            loadTime = nil
            onAdDismissed?()
        }
        isLoadingAd = false
    }
    // [END load_ad]
    
    // [START show_ad]
    func showAdIfAvailable() {
        // If the app open ad is already showing, do not show the ad again.
        if isShowingAd {
            return print("App open ad is already showing.")
        }
        
        // If the app open ad is not available yet but is supposed to show, load
        // a new ad.
        if !isAdAvailable() {
            print("App open ad is not ready yet.")
            // The app open ad is considered to be complete in this example.
            appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
            // Load a new ad.
            // [START_EXCLUDE silent]
//            Task {
//                await loadAd()
//            }
            // [END_EXCLUDE]
            return
        }
        
        if let appOpenAd {
            
            AdsManager.shared.isShowingAd = true
            
            appOpenAd.present(from: nil)
            isShowingAd = true
            
            
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
    // [END show_ad]
}

extension AppOpenAdManager: FullScreenContentDelegate {
    // [START ad_events]
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("App open ad recorded an impression.")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("App open ad recorded a click.")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad will be dismissed.")
        overlayView?.removeFromSuperview()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad will be presented.")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad was dismissed.")
        appOpenAd = nil
        isShowingAd = false
        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
        // Call the dismiss callback
        AdsManager.shared.isShowingAd = false
        onAdDismissed?()
        //    Task {
        //      await loadAd()
        //    }
    }
    
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("App open ad failed to present with error: \(error.localizedDescription)")
        appOpenAd = nil
        isShowingAd = false
        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
        AdsManager.shared.isShowingAd = false
        onAdDismissed?()
        overlayView?.removeFromSuperview()
        //    Task {
        //      await loadAd()
        //    }
    }
    // [END ad_events]
}
