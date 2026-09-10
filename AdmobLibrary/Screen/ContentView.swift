//
//  ContentView.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import SwiftUI
import AppTrackingTransparency
import UserNotifications

struct ContentView: View {
    
    private let consentManager = GoogleMobileAdsConsentManager.shared
    @State var isNextScreen = false
    
    
    @State private var showNetworkAlert = false
    @State private var showAdFailedAlert = false
    private let rewardedInterstitialManager = RewardAdManager()
    
    @State private var hasRequestedATT = false
    @State private var hasRequestedNotification = false
    @State private var isViewAppeared = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                
                Text("Hello, world!")
                    .onTapGesture {
                        isNextScreen = true
                    }
                
                Text("Show Reward")
                    .onTapGesture {
                        if NetworkMonitor.checkConnection() {
                            rewardedInterstitialManager.loadRewardedAdAd(
                                adUnitID: "",
                                onAdLoaded: {
                                    print("Quảng cáo đã load xong!")
                                },
                                onAdFailedToLoad: { error in
                                    print("Load quảng cáo thất bại: \(error.localizedDescription)")
                                    showAdFailedAlert = true
                                },
                                onAdDismissed: { isGranted in
                                    if isGranted {
                                        DispatchQueue.main.async {
                                           
                                        }
                                    }
                                })
                        } else {
                            showNetworkAlert = true
                        }
                    }
                
                VStack {
                    Spacer()
                    
                    nativeView(
                        configKey: "NATIVE",
                        onAdLoaded: {
                            
                        },
                        onAdFailedToLoad: { error in
                            
                        }
                    )
                    
                    adsBannerNativeView(
                        configKey: "ADS_HOME",
                        onAdLoaded: {
                            print("✅ ADS_HOME loaded")
                        },
                        onAdFailedToLoad: { error in
                            print("❌ ADS_HOME failed: \(error)")
                        }
                    )
                }
                
            }
            .ignoresSafeArea()
            .navigationDestination(isPresented: $isNextScreen) {
                SwiftUIView()
            }
            .alert("home.ad_failed_title".localized(), isPresented: $showAdFailedAlert) {
                Button("home.try_again".localized()) {
                    showAdFailedAlert = false
                }
                Button("home.cancel".localized(), role: .cancel) {
                    showAdFailedAlert = false
                }
            } message: {
                Text("home.ad_failed_message".localized())
            }
            .onAppear {
                if !isViewAppeared {
                    isViewAppeared = true
                    requestATTrackingPermission()
                }
            }
        }
    }
    
    
    // MARK: - ATT Permission
    private func requestATTrackingPermission() {
        guard !hasRequestedATT else {
            print("🚫 ATT already requested, skipping...")
            return
        }

        // Check current ATT status first
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        print("🔍 Current ATT status: \(currentStatus.rawValue)")

        // Only request if status is notDetermined
        guard currentStatus == .notDetermined else {
            print("⚠️ ATT status is not notDetermined, skipping request")
            hasRequestedATT = true
            return
        }

        print("⏰ Requesting ATT permission in 2 seconds...")
        print("🚀 Requesting ATT permission now...")
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                self.hasRequestedATT = true
                requestNotificationPermission()
                switch status {
                case .authorized:
                    print("✅ ATT permission granted")
                case .denied:
                    print("❌ ATT permission denied")
                case .restricted:
                    print("⚠️ ATT permission restricted")
                case .notDetermined:
                    print("❓ ATT permission not determined")
                @unknown default:
                    print("❓ ATT permission unknown status")
                }
            }
        }
    }

    // MARK: - Notification Permission
    /// Gọi sau ATT (delay) để không đụng 2 system alert cùng lúc.
    private func requestNotificationPermission() {
        guard !hasRequestedNotification else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Extract value here — UNNotificationSettings isn't Sendable
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                guard status == .notDetermined else {
                    self.hasRequestedNotification = true
                    return
                }

                // Đợi ATT dialog xong (~1.5s) rồi mới hỏi notification
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, error in
                    print("Notification permission: \(granted)")
                }
            }
        }
    }
    
    private func showWiFiInstruction() {
        let alert = UIAlertController(
            title: "home.wifi_instruction_title".localized(),
            message: "home.wifi_instruction_message".localized(),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "home.ok".localized(), style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
}

#Preview {
    ContentView()
}
