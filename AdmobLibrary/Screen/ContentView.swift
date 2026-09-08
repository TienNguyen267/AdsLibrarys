//
//  ContentView.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import SwiftUI

struct ContentView: View {
    
    private let consentManager = GoogleMobileAdsConsentManager.shared
    @State var isNextScreen = false
    
    
    @State private var showNetworkAlert = false
    @State private var showAdFailedAlert = false
    private let rewardedInterstitialManager = RewardAdManager()
    
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
