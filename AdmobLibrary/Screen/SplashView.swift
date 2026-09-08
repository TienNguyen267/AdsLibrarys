//
//  SplashView.swift

import SwiftUI
import Lottie

struct SplashView: View {
    @State private var showLanguageView = false
    @State private var consentGathered = false
    @State private var isLoadingConsent = true
    private let consentManager = GoogleMobileAdsConsentManager.shared
    
    @State var enableIntro = true
  
    var body: some View {
        
        if showLanguageView {
            ContentView()
        } else {
            ZStack {
              
            
                // Content layout similar to Android
                VStack(spacing: 0) {
                    Spacer()
                    

                    Image("appLogo") // Tên file ảnh logo của bạn
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.top, 120) // marginTop="120dp"
//
//                    // App Name (48sp equivalent = ~36 points)
//                    Image(.txtApp)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .padding(.top, 24) // layout_marginTop="24dp"
//                        .padding(.horizontal, 16)
//                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    VStack(spacing: 4) {
                        Text("WakeClock")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color(hex: "#FFE29A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)

                        Text("ALARM CHALLENGE")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(4)
                            .foregroundColor(Color(hex: "#FFE29A"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.28))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: "#FFE29A").opacity(0.6), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24) // layout_marginTop="24dp"
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
//
                
                    // Bottom text section
                    VStack(spacing: 0) {
                        Spacer()
                        // Lottie Animation
                       
                        Text("This action can contain ads...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        // AdMob Banner Ad with Shimmer and Interstitial (chỉ load sau khi có consent)
                        if consentGathered && !isLoadingConsent {
                            // Native Ad fixed ở chân màn hình với frame cố định
                            adView // Sát chân màn hình
                        } else if !isLoadingConsent {
                            adView
                        }
                    } .ignoresSafeArea(.container, edges: .all)
                }
            }
            .onAppear {
                // Request consent khi màn splash xuất hiện
                let defaults: [String: NSObject] = [
                    "isDebug": "0" as NSObject,
                    "checkTestAds": "0" as NSObject,
                    "INTER_HOME": "1" as NSObject,
                    "ADS_HOME": "1" as NSObject,
                    "autoCheckDebug": "1" as NSObject,
                ]
                RemoteConfigManager.shared.initRemoteConfig(defaults: defaults) {
                    
                    let isDebugFirebase = RemoteConfigManager.shared.getValue(forKey: "isDebug") == "1"
                    let autoCheckDebug = RemoteConfigManager.shared.getValue(forKey: "autoCheckDebug") == "1"
                    enableIntro = RemoteConfigManager.shared.getValue(forKey: "enableIntro") == "1"
                    Common.checkTestAds = RemoteConfigManager.shared.getValue(forKey: "checkTestAds") == "1"
                    
                    TenjinManager.shared.initialize(sdkKey: "")
            
            
                    DebugModeManager.shared.configureDebugFlag(rcValue: isDebugFirebase) { isDebug in
                        print("🔥 Common.isDebug = \(isDebug)")
                        Common.isDebug = autoCheckDebug ? isDebug : isDebugFirebase
                        requestConsent()
                    }
                }
            }
        }
        
         
    }
    
    var adView: some View {
        adsSplashView {
            showLanguageView = true
        }
        .ignoresSafeArea(.container, edges: .bottom)  // Sát chân màn hình
        .onAppear {
            OnResumeManager.shared.loadAd(adUnitID: "")
        }
    }
    
    
    func requestConsent() {
        print("🔵 Bắt đầu request consent...")
        isLoadingConsent = true
        
        Task { @MainActor in
            consentManager.gatherConsent { [self] consentError in
                isLoadingConsent = false
                
                if let consentError = consentError {
                    // Consent gathering failed.
                    print("❌ Lỗi khi gather consent: \(consentError.localizedDescription)")
                    // Vẫn có thể tiếp tục nhưng không load ads
                    consentGathered = false
                } else {
                    print("✅ Consent đã được gather thành công")
                    
                    // Check xem có thể request ads không
                    if consentManager.canRequestAds {
                        print("✅ Có thể request ads - Khởi tạo Google Mobile Ads SDK")
                        consentGathered = true
                        
                        // Khởi tạo Google Mobile Ads SDK
                        consentManager.startGoogleMobileAdsSDK()
                    } else {
                        print("⚠️ Không thể request ads - User có thể đã từ chối consent")
                        consentGathered = false
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
