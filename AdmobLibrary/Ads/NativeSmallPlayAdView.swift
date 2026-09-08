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
class NativeSmallPlayAdManager: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published var nativeAd: NativeAd?
    @Published var isLoading = false
    @Published var isloadFail = false
    
    private var adLoader: AdLoader?
    private var currentAdUnitID: String = ""
    
    // Callbacks for ad loading events
    var onAdLoaded: ((NativeAd) -> Void)?
    var onAdFailedToLoad: ((Error) -> Void)?
    
    override init() {
        super.init()
        print("🟢 NativeAdManager được khởi tạo")
    }
    
    func loadNativeAd(adUnitID: String, onLoaded: ((NativeAd) -> Void)? = nil, onFailed: ((Error) -> Void)? = nil) {
        // Set callbacks
        self.onAdLoaded = onLoaded
        self.onAdFailedToLoad = onFailed
    
        if(Common.isTestDevice) {
            print("Bỏ qua quảng cáo (Test Device hoặc Không có mạng hoặc tắt quảng cáo)")
            return
        }
        print("🔵 loadNativeAd được gọi với adUnitID: \(adUnitID)")
        print("🔵 isLoading hiện tại: \(isLoading)")
        
        guard !isLoading else { 
            print("⚠️ Đang loading rồi, bỏ qua request này")
            return 
        }
        
        isLoading = true
        isloadFail = false
        print("🔵 Đã set isLoading = true")
        
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        
        guard let rootViewController = getRootViewController() else {
            print("❌ No root view controller found")
            isLoading = false
            isloadFail = true
            return
        }
        
        print("✅ Root view controller tìm thấy: \(rootViewController)")
        let adID = Common.isDebug
            ? "ca-app-pub-3940256099942544/3986624511"
            : adUnitID
        self.currentAdUnitID = adUnitID
        adLoader = AdLoader(
            adUnitID: adID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [multipleAdsOptions]
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
        print("✅ Icon: \(nativeAd.icon != nil ? "có icon" : "nil")")
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
            self.nativeAd = nativeAd
            self.isloadFail = false
            print("✅ nativeAd đã được set, isLoading = \(self.isLoading)")
            
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
            // Call failure callback
            self.onAdFailedToLoad?(error)
            print("❌ onAdFailedToLoad callback đã được gọi")
        }
    }
    // MARK: - Test Device Detection
    
    private func checkIfTestDevice(nativeAd: NativeAd) {
        if !Common.checkTestAds {
            Common.isTestDevice = false
            return
        }
        
        guard let headline = nativeAd.headline else {
            print("===Native: No headline found")
            return
        }

        // Remove spaces and split by ":"
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

// Custom Native Ad View sử dụng XIB nhưng với layout tùy chỉnh
struct CustomNativeSmallAdView: UIViewRepresentable {
    let nativeAd: NativeAd
    
        
    func makeUIView(context: Context) -> NativeAdView {
        let nibView = Bundle.main.loadNibNamed("nativeAdSmallPlay", owner: nil, options: nil)?.first as? NativeAdView
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
struct NativeSmallAdSwiftUIView: View {
    let nativeAd: NativeAd
    
    var body: some View {
        // Sử dụng XIB version thay vì custom layout
        CustomNativeSmallAdView(nativeAd: nativeAd)
            .frame(height: 130) // Match height với XIB
    }
}


// Native Ad Container with loading state
struct NativeSmallPlayAdContainer: View {
    @StateObject private var adManager = NativeAdManager()
    let adUnitID: String
    @State private var hasAppeared = false
    
    // Callbacks
    let onAdLoaded: ((NativeAd) -> Void)?
    let onAdFailedToLoad: ((Error) -> Void)?
    
    init(adUnitID: String, onAdLoaded: ((NativeAd) -> Void)? = nil, onAdFailedToLoad: ((Error) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
        print("NativeAdContainer init với adUnitID: \(adUnitID)")
    }
    
    var body: some View {
        print("🟣 NativeAdContainer body được render")
        print("🟣 adManager.nativeAd: \(adManager.nativeAd != nil ? "có ad" : "nil")")
        
        return Group {
            if !Common.isTestDevice {
                if let nativeAd = adManager.nativeAd {
                    
                    NativeSmallAdSwiftUIView(nativeAd: nativeAd)
                } else {
                    // Luôn hiển thị loading view khi chưa có ad
                    if !adManager.isloadFail {
                        NativeSmallAdLoadingView()
                            .onAppear {
                                print("🟡 NativeAdLoadingView appeared")
                            }
                    }
                }
            }

        }
        .onAppear {
            print("🟠 NativeAdContainer onAppear được gọi")
            if !hasAppeared {
                hasAppeared = true
                print("🟠 Đang load native ad lần đầu tiên...")
                adManager.loadNativeAd(
                    adUnitID: adUnitID,
                    onLoaded: onAdLoaded,
                    onFailed: onAdFailedToLoad
                )
            } else {
                print("🟠 hasAppeared = true rồi, không load lại")
            }
        }
    }
}

// Loading view for native ad (skeleton shimmer) - match XIB layout
struct NativeSmallAdLoadingView: View {
    var body: some View {
        // Main container: 320x130
        ZStack {
            Color.white // Background color from XIB
            
            // Content container with 8pt padding (304x114)
            VStack(alignment: .leading, spacing: 0) {
                // Top section (304x58)
                HStack(alignment: .top, spacing: 4) {
                    // Icon container (50x50, corner radius 10)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(ShimmerEffect())
                    
                    // Text container (250x58)
                    VStack(alignment: .leading, spacing: 0) {
                        // Headline (250x17)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 250, height: 17)
                            .overlay(ShimmerEffect())
                            .padding(.bottom, 2)
                        
                        // Badge + Stars row (horizontally aligned)
                        HStack(alignment: .center, spacing: 8) {
                            // Badge (16x16, min width 30, corner radius 4, red background)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 30, height: 16)
                                .overlay(ShimmerEffect())
                            
                            // Stars (80x14)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 14)
                                .overlay(ShimmerEffect())
                        }
                        .padding(.bottom, 4)
                        
                        // Body (250x21, 2 lines)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 250, height: 21)
                            .overlay(ShimmerEffect())
                        
                        Spacer()
                    }
                    .frame(width: 250, height: 58)
                }
                .frame(height: 58)
                .padding(.bottom, 16)
                
                // CTA Button (304x40, corner radius 8, red background)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 304, height: 40)
                    .overlay(ShimmerEffect())
            }
            .frame(width: 304, height: 114)
            .padding(8)
        }
        .frame(width: 320, height: 130)
        .clipped()
    }
}


extension NativeSmallPlayAdManager: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        print("🟢 Native ad impression logged")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        print("🟠 Native ad click logged")
    }
}

