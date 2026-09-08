//
//  BannerAdView.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 11/10/25.
//

import SwiftUI
import GoogleMobileAds

private struct BannerAdView: UIViewRepresentable {
    typealias UIViewType = BannerView
    var adUnitID: String
    var isCollapsible: Bool
    var onAdLoaded: (() -> Void)?
    var onAdFailedToLoad: ((Error) -> Void)?
    
    init(adUnitID: String, isCollapsible: Bool,
         onAdLoaded: (() -> Void)? = nil,
         onAdFailedToLoad: ((Error) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.isCollapsible = isCollapsible
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
    }
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = Common.isDebug
            ? "ca-app-pub-3940256099942544/8388050270"
            : adUnitID
        banner.rootViewController = getRootViewController()
        banner.delegate = context.coordinator
        
//        let viewWidth = CGFloat(375)
//        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        
        // ✅ Lấy width thật của màn hình
        let viewWidth = UIScreen.main.bounds.width
        
        // ✅ Set adaptive size chuẩn
        banner.adSize = largeAnchoredAdaptiveBanner(width: viewWidth)
        
        let request = Request()
        // Chỉ load banner khi không phải test device
        if !Common.isTestDevice {
            
            if isCollapsible {
                let extras = Extras()
                extras.additionalParameters = ["collapsible" : "bottom"]
                request.register(extras)
            }
            
            banner.load(request)
        }
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
    
    class BannerCoordinator: NSObject, BannerViewDelegate {
        let parent: BannerAdView
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("Banner ad received successfully")
            DispatchQueue.main.async {
                self.parent.onAdLoaded?()
            }
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("Failed to receive banner ad: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.onAdFailedToLoad?(error)
            }
        }
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            bannerView.paidEventHandler = { adValue in
                PaidEventHandlerManager.shared.getPaidEventHandler(
                    dataPaidEvent: adValue,
                    typeAds: .bannerAds,
                    banner: bannerView,
                    adUnit: bannerView.adUnitID ?? "banner_default"
                )
            }
        }
    }
}

// Simple Loading View
struct ShimmerView: View {
    @State private var isAnimating = false
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.white.opacity(0.5),
                Color.clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: isAnimating ? 400 : -400)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// Banner Ad với Shimmer và Interstitial
struct BannerAdViewWithShimmer: View {
    var adUnitID: String
    var onAdLoaded: (() -> Void)?
    var onAdFailedToLoad: ((Error) -> Void)?
    
    @State private var isLoading = true
    @State private var shouldShowAd = true
    
    init(adUnitID: String, onAdLoaded: (() -> Void)? = nil,
         onAdFailedToLoad: ((Error) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
    }
    
    var body: some View {
        // Chỉ hiển thị banner khi không phải test device và shouldShowAd = true
        if !Common.isTestDevice && shouldShowAd {
            ZStack {
                // Shimmer loading
                if isLoading {
                    ShimmerView()
                        .frame(height: 50)
                }
                
                // Banner Ad
                BannerAdView(
                    adUnitID: adUnitID,
                    isCollapsible: false,
                    onAdLoaded: {
                        // Banner load thành công
                        isLoading = false
                        
                        // Load interstitial ad
                        DispatchQueue.main.async {
                            onAdLoaded?()
                        }
                    },
                    onAdFailedToLoad: { error in
                        // Banner load thất bại - ẩn toàn bộ view
                        print("Banner failed to load: \(error.localizedDescription)")
                        isLoading = false
                        shouldShowAd = false
                        DispatchQueue.main.async {
                            onAdFailedToLoad?(error)
                        }
                    }
                )
                .frame(height: 60)
                .opacity(isLoading ? 0 : 1)
            }
            .frame(height: 60)
        }
    }
}


struct BannerCollapsibleAdView: View {
    var adUnitID: String
    var onAdLoaded: (() -> Void)?
    var onAdFailedToLoad: ((Error) -> Void)?
    
    @State private var isLoading = true
    @State private var shouldShowAd = true
    
    init(adUnitID: String, onAdLoaded: (() -> Void)? = nil,
         onAdFailedToLoad: ((Error) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
    }
    
    var body: some View {
        // Chỉ hiển thị banner khi không phải test device và shouldShowAd = true
        if !Common.isTestDevice && shouldShowAd {
            ZStack {
                // Shimmer loading
                if isLoading {
                    ShimmerView()
                        .frame(height: 50)
                }
                
                // Banner Ad
                BannerAdView(
                    adUnitID: adUnitID,
                    isCollapsible: true,
                    onAdLoaded: {
                        // Banner load thành công
                        isLoading = false
                        
                        // Load interstitial ad
                        DispatchQueue.main.async {
                            onAdLoaded?()
                        }
                    },
                    onAdFailedToLoad: { error in
                        // Banner load thất bại - ẩn toàn bộ view
                        print("Banner failed to load: \(error.localizedDescription)")
                        isLoading = false
                        shouldShowAd = false
                        DispatchQueue.main.async {
                            onAdFailedToLoad?(error)
                        }
                    }
                )
                .frame(height: 60)
                .opacity(isLoading ? 0 : 1)
            }
            .frame(height: 60)
        }
    }
}

// Helper to get banner height
struct BannerAdViewHeightModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 60) // Standard banner height
    }
}

extension View {
    func bannerAdHeight() -> some View {
        modifier(BannerAdViewHeightModifier())
    }
}

