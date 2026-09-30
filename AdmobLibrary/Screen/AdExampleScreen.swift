//
//  AdExampleScreen.swift
//  AdmobLibrary
//

import SwiftUI
import AdmobLibrary

enum AdExample: String, CaseIterable, Identifiable, Hashable {
    case banner
    case bannerCollapsible
    case nativeMedium
    case nativeSmallPlay
    case nativeSmallBanner
    case nativeCollapsible
    case nativeCollapsibleClose
    case nativeFullscreen
    case interstitial
    case rewarded
    case rewardedInterstitial
    case appOpen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .banner: return "Banner"
        case .bannerCollapsible: return "Banner Collapsible"
        case .nativeMedium: return "Native Medium"
        case .nativeSmallPlay: return "Native Small Play"
        case .nativeSmallBanner: return "Native Small Banner"
        case .nativeCollapsible: return "Native Collapsible"
        case .nativeCollapsibleClose: return "Native Collapsible Close"
        case .nativeFullscreen: return "Native Fullscreen"
        case .interstitial: return "Interstitial"
        case .rewarded: return "Rewarded"
        case .rewardedInterstitial: return "Rewarded Interstitial"
        case .appOpen: return "App Open"
        }
    }

    var badge: String {
        switch self {
        case .banner: return "BN"
        case .bannerCollapsible: return "BC"
        case .nativeMedium: return "NM"
        case .nativeSmallPlay: return "NP"
        case .nativeSmallBanner: return "NS"
        case .nativeCollapsible: return "NC"
        case .nativeCollapsibleClose: return "NX"
        case .nativeFullscreen: return "NF"
        case .interstitial: return "IN"
        case .rewarded: return "RW"
        case .rewardedInterstitial: return "RI"
        case .appOpen: return "AO"
        }
    }

    var tint: Color {
        switch self {
        case .banner, .bannerCollapsible:
            return .blue
        case .nativeMedium, .nativeSmallPlay, .nativeSmallBanner, .nativeCollapsible, .nativeCollapsibleClose, .nativeFullscreen:
            return .orange
        case .interstitial, .rewarded, .rewardedInterstitial, .appOpen:
            return .purple
        }
    }

    var summary: String {
        switch self {
        case .banner:
            return "Banner thường, ghim dưới màn hình."
        case .bannerCollapsible:
            return "Banner mở rộng rồi thu lại khi user cuộn."
        case .nativeMedium:
            return "Native cỡ vừa, có media và CTA."
        case .nativeSmallPlay:
            return "Native nhỏ, nút play nổi bật."
        case .nativeSmallBanner:
            return "Native dẹt, cao gần bằng banner."
        case .nativeCollapsible:
            return "Native gọn, nằm sát chân màn hình."
        case .nativeCollapsibleClose:
            return "Native gọn, có nút đóng."
        case .nativeFullscreen:
            return "Native chiếm toàn màn, dùng giữa các bước."
        case .interstitial:
            return "Quảng cáo full screen, đóng xong mới đi tiếp."
        case .rewarded:
            return "User xem hết để nhận reward."
        case .rewardedInterstitial:
            return "Full screen, có reward nếu xem xong."
        case .appOpen:
            return "Hiện khi mở app hoặc quay lại từ background."
        }
    }

    var placement: String {
        switch self {
        case .banner, .bannerCollapsible, .nativeCollapsible, .nativeCollapsibleClose:
            return "Vị trí: chân màn hình"
        case .nativeMedium, .nativeSmallPlay, .nativeSmallBanner:
            return "Vị trí: trong nội dung"
        case .nativeFullscreen, .interstitial, .rewarded, .rewardedInterstitial, .appOpen:
            return "Vị trí: phủ toàn màn hình"
        }
    }

    var isFullscreen: Bool {
        switch self {
        case .nativeFullscreen, .interstitial, .rewarded, .rewardedInterstitial, .appOpen:
            return true
        default:
            return false
        }
    }
}

private enum AdTestUnit {
    static let banner = "ca-app-pub-3940256099942544/8388050270"
    static let native = "ca-app-pub-3940256099942544/3986624511"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    static let rewarded = "ca-app-pub-3940256099942544/1712485313"
    static let rewardedInterstitial = "ca-app-pub-3940256099942544/6978759866"
    static let appOpen = "ca-app-pub-3940256099942544/5575463023"
}

struct AdExampleScreen: View {
    let example: AdExample
    @Binding var showNetworkAlert: Bool

    @State private var status = "Chưa load"
    @State private var showCollapsibleClose = true
    @State private var showNativeFullscreen = false
    @State private var interstitialManager = InterstitialAdManager()
    @State private var rewardManager = RewardAdManager()
    @State private var rewardedInterstitialManager = RewardedInterstitialAdManager()
    @StateObject private var nativeFullscreenHolder = NativeHolderAdmob(adUnitID: AdTestUnit.native)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                if example.isFullscreen {
                    fullscreenBody
                } else {
                    inlineBody
                }
            }
        }
        .navigationTitle(example.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showNativeFullscreen) {
            ZStack(alignment: .topTrailing) {
                NativeAdFullScreenContainer(
                    nativeHolder: nativeFullscreenHolder,
                    onAdLoaded: { _ in status = "Đã load" },
                    onAdFailedToLoad: { error in
                        status = "Load thất bại: \(error.localizedDescription)"
                    }
                )
                .ignoresSafeArea()

                Button {
                    showNativeFullscreen = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(example.summary)
                .font(.body)
            Text(example.placement)
                .font(.caption.weight(.semibold))
                .foregroundStyle(example.tint)
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var inlineBody: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nội dung app")
                        .font(.headline)
                    Text("Phần này giả lập màn hình app. Quảng cáo bên dưới là example thật của \(example.title).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if example == .nativeMedium || example == .nativeSmallPlay || example == .nativeSmallBanner {
                        inlineAd
                            .padding(.top, 8)
                    }
                }
                .padding(20)
            }

            if example == .banner || example == .bannerCollapsible || example == .nativeCollapsible || example == .nativeCollapsibleClose {
                inlineAd
            }
        }
    }

    @ViewBuilder
    private var inlineAd: some View {
        switch example {
        case .banner:
            BannerAdViewWithShimmer(
                adUnitID: AdTestUnit.banner,
                onAdLoaded: { status = "Đã load" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                }
            )
        case .bannerCollapsible:
            BannerCollapsibleAdView(
                adUnitID: AdTestUnit.banner,
                onAdLoaded: { status = "Đã load" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                }
            )
        case .nativeMedium:
            NativeAdContainer(
                adUnitID: AdTestUnit.native,
                onAdLoaded: { _ in status = "Đã load" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                }
            )
            .frame(maxWidth: .infinity)
            .background(Color.white)
        case .nativeSmallPlay:
            NativeSmallPlayAdContainer(
                adUnitID: AdTestUnit.native,
                onAdLoaded: { _ in status = "Đã load" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                }
            )
            .frame(maxWidth: .infinity)
            .background(Color.white)
        case .nativeSmallBanner:
            NativeSmallBannerAdContainer(
                adUnitID: AdTestUnit.native,
                onAdLoaded: { _ in status = "Đã load" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                }
            )
            .frame(maxWidth: .infinity)
            .background(Color.white)
        case .nativeCollapsible:
            NativeCollapAdContainer(
                adUnitID: AdTestUnit.native,
                onAdLoaded: { _ in status = "Đã load" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                }
            )
            .frame(maxWidth: .infinity)
            .background(Color.white)
        case .nativeCollapsibleClose:
            if showCollapsibleClose {
                NativeCollapCloseAdContainer(
                    adUnitID: AdTestUnit.native,
                    onAdLoaded: { _ in status = "Đã load" },
                    onAdFailedToLoad: { error in
                        status = "Load thất bại: \(error.localizedDescription)"
                    },
                    onAdClose: {
                        showCollapsibleClose = false
                        status = "User đã đóng ad"
                    }
                )
                .frame(maxWidth: .infinity)
                .background(Color.white)
            } else {
                Button("Hiện lại example") {
                    showCollapsibleClose = true
                    status = "Đang load lại"
                }
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
        default:
            EmptyView()
        }
    }

    private var fullscreenBody: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Bấm nút để load và hiện example.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(action: showFullscreenAd) {
                Text("Xem \(example.title)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(example.tint)
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    private func showFullscreenAd() {
        guard NetworkMonitor.checkConnection() else {
            showNetworkAlert = true
            return
        }

        status = "Đang load..."

        switch example {
        case .interstitial:
            interstitialManager.loadInterstitialAd(
                adUnitID: AdTestUnit.interstitial,
                onAdLoaded: { status = "Đang hiện" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                },
                onAdDismissed: { status = "User đã đóng ad" }
            )
        case .rewarded:
            rewardManager.loadRewardedAdAd(
                adUnitID: AdTestUnit.rewarded,
                onAdLoaded: { status = "Đang hiện" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                },
                onAdDismissed: { granted in
                    status = granted ? "Đã nhận reward" : "Đóng, chưa nhận reward"
                }
            )
        case .rewardedInterstitial:
            rewardedInterstitialManager.loadRewardedAdAd(
                adUnitID: AdTestUnit.rewardedInterstitial,
                onAdLoaded: { status = "Đang hiện" },
                onAdFailedToLoad: { error in
                    status = "Load thất bại: \(error.localizedDescription)"
                },
                onAdDismissed: { granted in
                    status = granted ? "Đã nhận reward" : "Đóng, chưa nhận reward"
                }
            )
        case .appOpen:
            Task { @MainActor in
                await AppOpenAdManager.shared.loadAOA(adUnitID: AdTestUnit.appOpen) {
                    status = "User đã đóng ad"
                }
            }
        case .nativeFullscreen:
            showNativeFullscreen = true
        default:
            break
        }
    }
}

#Preview {
    NavigationStack {
        AdExampleScreen(example: .banner, showNetworkAlert: .constant(false))
    }
}
