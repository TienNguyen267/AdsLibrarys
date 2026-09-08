//
//  AdsSplash.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import Foundation
import SwiftUI
import Combine

@ViewBuilder
func adsSplashView(
    onAdDismiss: @escaping (() -> Void),
) -> some View {
    AdsSplashContainerView(onAdDismiss: onAdDismiss)
}

private struct AdsSplashContainerView: View {
    let onAdDismiss: () -> Void

    @StateObject private var nativeAdManager = NativeAdFullScreenManager()

    var body: some View {
        splashContent
    }

    @ViewBuilder
    private var splashContent: some View {
        if let splash = RemoteConfigManager.shared.getValue(forKey: "ADS_SPLASH", as: SplashConfig.self) {

            switch splash.bannerSplash {

            case "1" :
                BannerAdViewWithShimmer(
                    adUnitID: splash.units.banner,
                    onAdLoaded: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            print("✅ Load Inter sau 2 giây")
                            loadAD(splash: splash)
                        }
                    },
                    onAdFailedToLoad: { error in
                        loadAD(splash: splash)
                    }
                )

            case "2" :
                switch splash.nativeType {
                case "1":
                    NativeAdContainer(
                        adUnitID: splash.units.native,
                        onAdLoaded: { nativeAd in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                print("✅ Load Inter sau 2 giây")
                                loadAD(splash: splash)
                            }
                        },
                        onAdFailedToLoad: { error in
                            loadAD(splash: splash)
                        }
                    )
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)

                case "2":
                    NativeSmallPlayAdContainer(
                        adUnitID: splash.units.native,
                        onAdLoaded: { nativeAd in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                print("✅ Load Inter sau 2 giây")
                                loadAD(splash: splash)
                            }
                        },
                        onAdFailedToLoad: { error in
                            loadAD(splash: splash)
                        }
                    )
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)

                case "3":
                    NativeSmallBannerAdContainer(
                        adUnitID: splash.units.native,
                        onAdLoaded: { nativeAd in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                print("✅ Load Inter sau 2 giây")
                                loadAD(splash: splash)
                            }
                        },
                        onAdFailedToLoad: { error in
                            loadAD(splash: splash)
                        }
                    )
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)

                case "4":
                    NativeCollapAdContainer(
                        adUnitID: splash.units.native,
                        onAdLoaded: { nativeAd in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                print("✅ Load Inter sau 2 giây")
                                loadAD(splash: splash)
                            }
                        },
                        onAdFailedToLoad: { error in
                            loadAD(splash: splash)
                        }
                    )
                    .ignoresSafeArea()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                default :
                    Color.clear.onAppear {
                        loadAD(splash: splash)
                    }
                }

            default :
                Color.clear.onAppear {
                    loadAD(splash: splash)
                }
            }

        } else {
            Color.clear.onAppear {
                onAdDismiss()
            }
        }
    }

    private func checkAndShowNativeOrClose() {
        if Common.isTestDevice {
            onAdDismiss()
            return
        }
        if nativeAdManager.nativeAd != nil {
            print("✅ Native fullscreen ad đã load - Hiển thị native fullscreen")
            NativeFullScreenAdPresenter.shared.show(
                nativeAdManager: nativeAdManager,
                onClose: { onAdDismiss() }
            )
        } else {
            print("❌ Chưa có native fullscreen ad - Chuyển thẳng sang language")
            onAdDismiss()
        }
    }

    private func loadAD(splash: SplashConfig) {
        let viewModel = InterstitialAdManager()
        SplashAdHolder.interstitialManager = viewModel
        SplashAdHolder.nativeManager = nativeAdManager

        switch splash.adsSplash {
        case "1":
            Task {
                await AppOpenAdManager.shared.loadAOA(adUnitID: splash.units.aoa, onAdDismissed: {
                    onAdDismiss()
                })
            }

        case "2":
            viewModel.loadInterstitialAd(
                adUnitID: splash.units.inter,
                onAdLoaded: {
                    print("✅ Interstitial ad đã load xong!")
                },
                onAdFailedToLoad: { error in
                    print("❌ Load interstitial ad thất bại: \(error.localizedDescription)")
                    onAdDismiss()
                },
                onAdDismissed: {
                    print("🔴 Người dùng đã tắt interstitial ad")
                    onAdDismiss()
                }
            )

        case "3":
            viewModel.loadInterstitialAd(
                adUnitID: splash.units.inter,
                onAdLoaded: {
                    print("✅ Interstitial ad đã load xong!")
                    nativeAdManager.loadNativeAd(
                        nativeHolder: NativeHolderAdmob(adUnitID: splash.units.nativeFullscreen)
                    )
                },
                onAdFailedToLoad: { error in
                    print("❌ Load interstitial ad thất bại: \(error.localizedDescription)")
                    checkAndShowNativeOrClose()
                },
                onAdDismissed: {
                    print("🔴 Người dùng đã tắt interstitial ad")
                    checkAndShowNativeOrClose()
                }
            )

        case "0":
            onAdDismiss()

        default:
            onAdDismiss()
        }
    }
}

// Giữ tham chiếu mạnh để manager không bị giải phóng trước khi ad load/show xong
private enum SplashAdHolder {
    static var interstitialManager: InterstitialAdManager?
    static var nativeManager: NativeAdFullScreenManager?
}

// MARK: - Native FullScreen overlay hiển thị trên 1 UIWindow riêng (đè lên tất cả view)

private struct NativeFullScreenAdOverlayView: View {
    @ObservedObject var nativeAdManager: NativeAdFullScreenManager
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.white.opacity(0.5)
                .ignoresSafeArea()

            if let nativeAd = nativeAdManager.nativeAd {
                NativeAdFullScreenSwiftUIView(nativeAd: nativeAd)
            } else {
                NativeAdFullScreenLoadingView()
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding(.top, 48)
                    .padding(.trailing, 8)
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.container, edges: .all)
    }
}

final class NativeFullScreenAdPresenter {
    static let shared = NativeFullScreenAdPresenter()

    private var window: UIWindow?
    private var hostingController: UIViewController?

    private init() {}

    func show(nativeAdManager: NativeAdFullScreenManager, onClose: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                print("❌ Không tìm thấy window scene")
                onClose()
                return
            }

            let overlay = NativeFullScreenAdOverlayView(
                nativeAdManager: nativeAdManager,
                onClose: { [weak self] in
                    self?.hide()
                    onClose()
                }
            )

            let window = UIWindow(windowScene: windowScene)
            window.windowLevel = .alert + 1 // Hiển thị trên tất cả
            window.backgroundColor = .clear

            let hostingController = UIHostingController(rootView: overlay)
            hostingController.view.backgroundColor = .clear

            window.rootViewController = hostingController
            window.makeKeyAndVisible()

            self.window = window
            self.hostingController = hostingController

            print("✅ Đã hiển thị native fullscreen ad overlay")
        }
    }

    func hide() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.window?.isHidden = true
            self.window = nil
            self.hostingController = nil
            print("✅ Đã ẩn native fullscreen ad overlay")
        }
    }
}
