//
//  NativeCollapAdView.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 13/10/25.
//

import SwiftUI
import GoogleMobileAds
import Combine

// Custom Native Collap Ad View sử dụng XIB nhưng với layout tùy chỉnh
struct CustomNativeCollapAdView: UIViewRepresentable {
    let nativeAd: NativeAd
    @Binding var isCollapsed: Bool
    let onClose: (() -> Void)?
    func makeUIView(context: Context) -> NativeAdView {

        guard let nativeAdView = Bundle.main.loadNibNamed("nativeMediumCollap", owner: nil, options: nil)?.first as? NativeAdView else {
            print("❌ Không thể load NativeAdView từ XIB nativeMediumCollap")
            return NativeAdView()
        }

        if let closeButton = nativeAdView.viewWithTag(999) as? UIButton {
            closeButton.addTarget(context.coordinator, action: #selector(Coordinator.closeButtonTapped), for: .touchUpInside)
        } else {
            // Nếu không tìm thấy bằng tag, tìm bằng accessibilityIdentifier hoặc duyệt subviews
            findCloseButton(in: nativeAdView)?.addTarget(context.coordinator, action: #selector(Coordinator.closeButtonTapped), for: .touchUpInside)
        }
        
        return nativeAdView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        
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
    
    private func findCloseButton(in view: UIView) -> UIButton? {
        // Tìm close button bằng cách kiểm tra title "×"
        for subview in view.subviews {
            if let button = subview as? UIButton,
               button.title(for: .normal) == "×" {
                print("✅ Tìm thấy close button với title '×'")
                return button
            }
        }
        
        // Nếu không tìm thấy, tìm button đầu tiên (fallback)
        for subview in view.subviews {
            if let button = subview as? UIButton {
                print("✅ Tìm thấy close button (fallback - button đầu tiên)")
                return button
            }
        }
        
        print("❌ Không tìm thấy close button")
        return nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isCollapsed: $isCollapsed, onClose: onClose)
    }
    
    class Coordinator: NSObject {
        @Binding var isCollapsed: Bool
        let onClose: (() -> Void)?
        
        init(isCollapsed: Binding<Bool>, onClose: (() -> Void)?) {
            _isCollapsed = isCollapsed
            self.onClose = onClose
        }
        
        @objc func closeButtonTapped() {
            print("🔴 Close button tapped - collapsing ad...")
            isCollapsed = true
            onClose?() // 🔥 Trigger callback
        }
    }
}

// SwiftUI Native Collap Ad View with MediaView (Android-style layout)
struct NativeCollapAdSwiftUIView: View {
    let nativeAd: NativeAd
    var isClose : Bool = false
    var onClose: (() -> Void)? = nil
    @State private var isCollapsed: Bool = false
    
    var body: some View {
        Group {
            if isCollapsed {
                // Custom compact layout khi collapsed
                if !isClose {
                    CollapsedAdView(nativeAd: nativeAd, isCollapsed: $isCollapsed)
                }
            } else {
                // XIB layout khi expanded
                CustomNativeCollapAdView(nativeAd: nativeAd, isCollapsed: $isCollapsed, onClose: onClose)
                    .frame(maxHeight: 280)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
    }
}

// Custom compact ad view khi collapsed
struct CollapsedAdView: View {
    let nativeAd: NativeAd
    @Binding var isCollapsed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = nativeAd.icon?.image {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Headline
                    if let headline = nativeAd.headline {
                        Text(headline)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Ad badge
                    Text("Ad")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "D22F26"))
                        .cornerRadius(4)
                }
                
                // Body
                if let body = nativeAd.body {
                    Text(body)
                        .font(.system(size: 9))
                        .foregroundColor(.black)
                        .lineLimit(2)
                }
            }
            
            // CTA Button
            if let cta = nativeAd.callToAction {
                Button(action: {
                    // Handle CTA action
                }) {
                    Text(cta)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "D22F26"))
                        .cornerRadius(8)
                }
                .frame(width: 100)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .frame(height: 60) // Fixed compact height
    }
}


// Native Collap Ad Container with loading state
struct NativeCollapAdContainer: View {
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
        print("NativeCollapAdContainer init với adUnitID: \(adUnitID)")
    }
    
    var body: some View {
        print("🟣 NativeCollapAdContainer body được render")
        print("🟣 adManager.nativeAd: \(adManager.nativeAd != nil ? "có ad" : "nil")")
        
        return Group {
            if !Common.isTestDevice {
                if let nativeAd = adManager.nativeAd {
                    NativeCollapAdSwiftUIView(nativeAd: nativeAd)
                } else {
                    // Luôn hiển thị loading view khi chưa có ad
                    if !adManager.isloadFail {
                        NativeCollapAdLoadingView()
                            .onAppear {
                                print("🟡 NativeCollapAdLoadingView appeared")
                            }
                    }
                }
            }
        }
        .onAppear {
            print("🟠 NativeCollapAdContainer onAppear được gọi")
            if !hasAppeared {
                hasAppeared = true
                print("🟠 Đang load native collap ad lần đầu tiên...")
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

struct NativeCollapCloseAdContainer: View {
    @StateObject private var adManager = NativeAdManager()
    let adUnitID: String
    @State private var hasAppeared = false
    
    // Callbacks
    let onAdLoaded: ((NativeAd) -> Void)?
    let onAdFailedToLoad: ((Error) -> Void)?
    let onAdClose: (() -> Void)?
    
    init(adUnitID: String, onAdLoaded: ((NativeAd) -> Void)? = nil, onAdFailedToLoad: ((Error) -> Void)? = nil, onAdClose: (() -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
        self.onAdClose = onAdClose
        print("NativeCollapAdContainer init với adUnitID: \(adUnitID)")
    }
    
    var body: some View {
        print("🟣 NativeCollapAdContainer body được render")
        print("🟣 adManager.nativeAd: \(adManager.nativeAd != nil ? "có ad" : "nil")")
        
        return Group {
            if !Common.isTestDevice {
                if let nativeAd = adManager.nativeAd {
                    NativeCollapAdSwiftUIView(nativeAd: nativeAd, isClose : true, onClose: {
                        print("🧨 onAdClose callback triggered")
                        onAdClose?() // 🔥 callback ra cha
                    })
                } else {
                    // Luôn hiển thị loading view khi chưa có ad
                    if !adManager.isloadFail {
                        NativeCollapAdLoadingView()
                            .onAppear {
                                print("🟡 NativeCollapAdLoadingView appeared")
                            }
                    }
                }
            }
        }
        .onAppear {
            print("🟠 NativeCollapAdContainer onAppear được gọi")
            if !hasAppeared {
                hasAppeared = true
                print("🟠 Đang load native collap ad lần đầu tiên...")
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

// Loading view for native collap ad (skeleton shimmer) - match XIB height
struct NativeCollapAdLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section với close button
            HStack(alignment: .top, spacing: 0) {
                // Logo + Title + Desc
                HStack(alignment: .top, spacing: 8) {
                    // Logo placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 40, height: 40)
                        .overlay(ShimmerCollapEffect())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Title placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 120, height: 16)
                            .overlay(ShimmerCollapEffect())
                        
                        // Description placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 180, height: 14)
                            .overlay(ShimmerCollapEffect())
                    }
                }
                
                Spacer()
                
                // Close button placeholder
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 24, height: 24)
                    .overlay(ShimmerCollapEffect())
            }
            .padding(.bottom, 12)
            
            // Rating placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(uiColor: .systemGray5))
                .frame(width: 80, height: 14)
                .overlay(ShimmerCollapEffect())
                .padding(.bottom, 5)
            
            // Media content placeholder (large area)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .systemGray5))
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .overlay(ShimmerCollapEffect())
                .padding(.bottom, 5)
            
            // CTA Button placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .systemGray5))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .overlay(ShimmerCollapEffect())
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            // Ad badge overlay
            VStack {
                HStack {
                    Text("Ad")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.7))
                        .cornerRadius(4)
                        .padding(4)
                    Spacer()
                }
                Spacer()
            }
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .frame(height: 300)
    }
}

// Shimmer effect for collap ad loading animation
struct ShimmerCollapEffect: View {
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

