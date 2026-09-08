//
//  NativeAdView.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 11/10/25.
//

import SwiftUI
import GoogleMobileAds
import Combine

// Native Ad Manager
class NativeAdFullScreenManager: NSObject, ObservableObject, NativeAdLoaderDelegate {
    
    // Singleton
    static let shared = NativeAdFullScreenManager()
    
    @Published var nativeAd: NativeAd?
    @Published var isLoading = false
    @Published var isloadFail = false
    
    private var adLoader: AdLoader?
    private var currentAdUnitID: String = ""
    
    // giữ reference tới holder hiện tại để update state
    private weak var currentHolder: NativeHolderAdmob?

    // Callbacks for ad loading events
    var onAdLoaded: ((NativeAd) -> Void)?
    var onAdFailedToLoad: ((Error) -> Void)?
    
    override init() {
        super.init()
        print("🟢 NativeAdManager được khởi tạo")
    }
    
    // ⚡️ MỚI: dùng NativeHolderAdmob thay vì adUnitID String
    func loadNativeAd(
        nativeHolder: NativeHolderAdmob,
        onLoaded: ((NativeAd) -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) {
        // Set callbacks
        self.onAdLoaded = onLoaded
        self.onAdFailedToLoad = onFailed
        self.currentHolder = nativeHolder
        
        print("🔵 loadNativeAd được gọi với holder.adsID: \(nativeHolder.adsID)")
        print("🔵 Common.isTestDevice: \(Common.isTestDevice)")
        print("🔵 Manager.isLoading hiện tại: \(isLoading)")
        print("🔵 Holder.isLoading hiện tại: \(nativeHolder.isLoading)")
        
        if(Common.isTestDevice) {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            return
        }
        
        // Guard đang loading
        guard !isLoading else {
            print("⚠️ Manager đang loading rồi, bỏ qua request này")
            return
        }
        guard !nativeHolder.isLoading else {
            print("⚠️ Holder này đang loading rồi, bỏ qua request này")
            return
        }
        
        isLoading = true
        isloadFail = false
        nativeHolder.isLoading = true
        print("🔵 Đã set isLoading = true (manager + holder)")
        
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        
        guard let rootViewController = getRootViewController() else {
            print("❌ No root view controller found")
            isLoading = false
            isloadFail = true
            nativeHolder.isLoading = false
            return
        }
        
        let adID = Common.isDebug
            ? "ca-app-pub-3940256099942544/3986624511"
            : nativeHolder.adsID
        
        self.currentAdUnitID = nativeHolder.adsID

        print("✅ Root view controller tìm thấy: \(rootViewController)")
        let aspectRatioOption = NativeAdMediaAdLoaderOptions()
        aspectRatioOption.mediaAspectRatio = .any
        
        adLoader = AdLoader(
            adUnitID: adID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [aspectRatioOption]
        )
        
        print("✅ AdLoader đã được khởi tạo")
        adLoader?.delegate = self
        print("✅ Delegate đã được set")
        
        let request = Request()
        print("✅ Đang gọi adLoader.load()...")
        adLoader?.load(request)
        print("✅ adLoader.load() đã được gọi")
    }
    
    // MARK: - GADNativeAdLoaderDelegate
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("✅✅✅ Native ad received successfully!")
        print("✅ Headline: \(nativeAd.headline ?? "nil")")
        print("✅ Advertiser: \(nativeAd.advertiser ?? "nil")")
        print("✅ Body: \(nativeAd.body ?? "nil")")
        print("✅ CTA: \(nativeAd.callToAction ?? "nil")")
        print("✅ MediaContent aspect ratio: \(nativeAd.mediaContent.aspectRatio)")
        print("✅ MediaContent hasVideoContent: \(nativeAd.mediaContent.hasVideoContent)")
        print("✅ Star Rating: \(nativeAd.starRating?.doubleValue ?? 0)")
        
        nativeAd.delegate = self
        print("✅ nativeAd.delegate = self (để lắng nghe ad_impression)")
        
        nativeAd.paidEventHandler = { [weak self] adValue in
            guard let self = self else { return }

            let adUnitId = self.currentAdUnitID
            PaidEventHandlerManager.shared.getPaidEventHandler(
                dataPaidEvent: adValue,
                typeAds: .nativeAds,
                native: nativeAd,
                adUnit: adUnitId
            )
        }
        // Check if it's a test ad
        checkIfTestDevice(nativeAd: nativeAd)
        
        DispatchQueue.main.async {
            print("✅ Updating UI với native ad...")
            self.isLoading = false
            self.isloadFail = false
            self.nativeAd = nativeAd
            
            if let holder = self.currentHolder {
                holder.isLoading = false
                holder.nativeAd = nativeAd
                print("✅ Holder.nativeAd đã được set, holder.isLoading = \(holder.isLoading)")
            } else {
                print("⚠️ currentHolder nil, không update được holder")
            }
            
            // Call success callback
            self.onAdLoaded?(nativeAd)
            print("✅ onAdLoaded callback đã được gọi")
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌❌❌ Failed to receive native ad!")
        print("❌ Error: \(error.localizedDescription)")
        print("❌ Full error: \(error)")
        
        DispatchQueue.main.async {
            print("❌ Setting isLoading = false")
            self.isLoading = false
            self.isloadFail = true
            
            if let holder = self.currentHolder {
                holder.isLoading = false
                print("❌ Holder.isLoading = false")
            }
            
            // Call failure callback
            self.onAdFailedToLoad?(error)
            print("❌ onAdFailedToLoad callback đã được gọi")
        }
    }
    
    // MARK: - Test Device Detection (giữ nguyên)
    
    private func checkIfTestDevice(nativeAd: NativeAd) {
        if !Common.checkTestAds {
            Common.isTestDevice = false
            return
        }
        
        guard let headline = nativeAd.headline else {
            print("===Native: No headline found")
            return
        }

        let testAdResponse = headline.replacingOccurrences(of: " ", with: "")
            .split(separator: ":")
            .first
            .map(String.init) ?? ""

        let testAdResponses = [
            "Testmode",
            "TestAd",
            "Anunciodeprueba",
            "Annuncioditesto",
            "Testanzeige",
            "TesIklan",
            "Anúnciodeteste",
            "Тестовоеобъявление",
            "পরীক্ষামূলকবিজ্ঞাপন",
            "जाँचविज्ञापन",
            "إعلانتجريبي",
            "Quảngcáothửnghiệm"
        ]

        Common.isTestDevice = testAdResponses.contains(testAdResponse)
        print("===TestDevice===", "isTestDevice: \(Common.isTestDevice)")
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}

extension NativeAdFullScreenManager: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        print("🟢 Native ad impression logged")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        print("🟠 Native ad click logged")
    }
}

// Native Ad View (UIKit wrapper)
struct NativeAdFullScreenViewWrapper: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdView {
        let nibView = Bundle.main.loadNibNamed("nativeAdFullScreen", owner: nil, options: nil)?.first as? NativeAdView
        guard let adView = nibView else {
            return NativeAdView()
        }
        
        return adView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        // Set the native ad
        nativeAdView.nativeAd = nativeAd
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        // Configure ad view elements
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        nativeAdView.headlineView?.isHidden = nativeAd.headline == nil
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
    }
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}

// Custom Native Ad View sử dụng XIB nhưng với layout tùy chỉnh
struct CustomNativeAdFullScreenView: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdView {
        let nibView = Bundle.main.loadNibNamed("nativeAdFullScreen", owner: nil, options: nil)?.first as? NativeAdView
        guard let adView = nibView else {
            return NativeAdView()
        }
        
        return adView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        // Set the native ad
        nativeAdView.nativeAd = nativeAd
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        // Configure ad view elements
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        nativeAdView.headlineView?.isHidden = nativeAd.headline == nil
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
    }
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}

// SwiftUI Native Ad View with MediaView (Android-style layout)
struct NativeAdFullScreenSwiftUIView: View {
    let nativeAd: NativeAd
    
    var body: some View {
        // Sử dụng XIB version thay vì custom layout
        CustomNativeAdFullScreenView(nativeAd: nativeAd)
    }
}

// Native Ad Container with loading state (standalone - loads its own ad)
// Native Ad Container with loading state (dùng NativeHolderAdmob)
struct NativeAdFullScreenContainer: View {
    @ObservedObject var nativeHolder: NativeHolderAdmob
    @StateObject private var adManager = NativeAdFullScreenManager()
    
    @State private var hasAppeared = false
    
    // Callbacks
    let onAdLoaded: ((NativeAd) -> Void)?
    let onAdFailedToLoad: ((Error) -> Void)?
    
    init(
        nativeHolder: NativeHolderAdmob,
        onAdLoaded: ((NativeAd) -> Void)? = nil,
        onAdFailedToLoad: ((Error) -> Void)? = nil
    ) {
        self.nativeHolder = nativeHolder
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
        print("NativeAdFullScreenContainer init với adsID: \(nativeHolder.adsID)")
    }
    
    var body: some View {
        print("🟣 NativeAdFullScreenContainer body được render")
        print("🟣 nativeHolder.nativeAd: \(nativeHolder.nativeAd != nil ? "có ad" : "nil")")
        print("🟣 nativeHolder.isLoading: \(nativeHolder.isLoading)")
        print("🟣 Common.isTestDevice: \(Common.isTestDevice)")
        
        return Group {
            if let nativeAd = nativeHolder.nativeAd {
                // Có ad → show full screen native
                NativeAdFullScreenSwiftUIView(nativeAd: nativeAd)
            } else {
                // Chưa có ad → show loading (skeleton)
                if !adManager.isloadFail {
                    NativeAdFullScreenLoadingView()
                        .onAppear {
                            print("🟡 NativeAdFullScreenLoadingView appeared")
                        }
                }
            }
        }
        .onAppear {
            print("🟠 NativeAdFullScreenContainer onAppear được gọi")
            if !hasAppeared {
                hasAppeared = true
                print("🟠 Đang load native ad lần đầu tiên...")
                
                // Reset test flag nếu bro muốn
                Common.isTestDevice = false
                
                adManager.loadNativeAd(
                    nativeHolder: nativeHolder,
                    onLoaded: { ad in
                        onAdLoaded?(ad)
                    },
                    onFailed: { error in
                        onAdFailedToLoad?(error)
                    }
                )
            } else {
                print("🟠 hasAppeared = true rồi, không load lại")
            }
        }
    }
}

// Loading view for native ad (skeleton shimmer) - match XIB height
struct NativeAdFullScreenLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background: Fullscreen Media placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.094, green: 0.145, blue: 0.176)) // Match XIB background color
                .overlay(ShimmerFullScreenEffect())
            
            // Bottom content overlay
            VStack(spacing: 0) {
                Spacer()
                
                // Content view (icon, headline, star rating, body)
                HStack(alignment: .top, spacing: 8) {
                    // Icon placeholder (50x50)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 50, height: 50)
                        .overlay(ShimmerFullScreenEffect())
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Headline placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 120, height: 14.5)
                            .overlay(ShimmerFullScreenEffect())
                            .padding(.bottom, 4)
                        
                        // Star rating placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 80, height: 12)
                            .overlay(ShimmerFullScreenEffect())
                            .padding(.bottom, 0)
                        
                        // Body placeholder (2 lines)
                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(uiColor: .systemGray5))
                                .frame(width: 240, height: 10)
                                .overlay(ShimmerFullScreenEffect())
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(uiColor: .systemGray5))
                                .frame(width: 200, height: 10)
                                .overlay(ShimmerFullScreenEffect())
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // CTA Button placeholder (height 50)
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(red: 0.0, green: 0.459, blue: 0.890)) // Match XIB button color
                    .frame(height: 50)
                    .overlay(
                        Text("Open")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .overlay(ShimmerFullScreenEffect())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Shimmer effect for loading animation
struct ShimmerFullScreenEffect: View {
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

