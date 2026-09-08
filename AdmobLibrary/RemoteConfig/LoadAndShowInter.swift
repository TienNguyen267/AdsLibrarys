//
//  AdsSplash.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import Foundation
import SwiftUI
import Combine


func loadAndShowInter(
    configKey: String,
    onAdDismiss: @escaping (() -> Void)
) {
    let runner = InterAdRunner(key: configKey, onAdDismiss: onAdDismiss)
    InterAdHolder.runner = runner
    runner.loadAD()
}

final class InterAdRunner {

    private let key: String
    private let onAdDismiss: () -> Void
    private let nativeAdManager = NativeAdFullScreenManager()

    init(key: String, onAdDismiss: @escaping () -> Void) {
        self.key = key
        self.onAdDismiss = onAdDismiss
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
                onClose: { [weak self] in self?.onAdDismiss() }
            )
        } else {
            print("❌ Chưa có native fullscreen ad - Chuyển thẳng sang language")
            onAdDismiss()
        }
    }

    func loadAD() {
        let viewModel = InterstitialAdManager()
        InterAdHolder.interstitialManager = viewModel
        InterAdHolder.nativeManager = nativeAdManager

        if let inter = RemoteConfigManager.shared.getValue(forKey: key, as: InterConfig.self) {

            // count = số lần cách nhau giữa 2 quảng cáo (frequency capping)
            // Lần đầu tiên hiển thị ngay, sau đó cứ cách `count` lần mới hiển thị lại.
            // Bộ đếm chỉ giữ trong bộ nhớ -> kill app là reset lại
            let capping = Int(inter.count) ?? 0
            if capping > 0 {
                let calls = InterAdHolder.cappingCounters[key] ?? 0
                InterAdHolder.cappingCounters[key] = calls + 1
                if calls % (capping + 1) != 0 {
                    print("⏭️ Chưa tới lượt hiển thị Inter (cách nhau \(capping) lần) - Bỏ qua")
                    onAdDismiss()
                    return
                }
            }

            switch inter.type {
            case "1":
                viewModel.loadInterstitialAd(
                    adUnitID: inter.units.inter,
                    onAdLoaded: {
                        print("✅ Interstitial ad đã load xong!")
                    },
                    onAdFailedToLoad: { [weak self] error in
                        print("❌ Load interstitial ad thất bại: \(error.localizedDescription)")
                        self?.onAdDismiss()
                    },
                    onAdDismissed: { [weak self] in
                        print("🔴 Người dùng đã tắt interstitial ad")
                        self?.onAdDismiss()
                    }
                )

            case "2":
                viewModel.loadInterstitialAd(
                    adUnitID: inter.units.inter,
                    onAdLoaded: { [weak self] in
                        print("✅ Interstitial ad đã load xong!")
                        self?.nativeAdManager.loadNativeAd(
                            nativeHolder: NativeHolderAdmob(adUnitID: inter.units.native)
                        )
                    },
                    onAdFailedToLoad: { [weak self] error in
                        print("❌ Load interstitial ad thất bại: \(error.localizedDescription)")
                        self?.checkAndShowNativeOrClose()
                    },
                    onAdDismissed: { [weak self] in
                        print("🔴 Người dùng đã tắt interstitial ad")
                        self?.checkAndShowNativeOrClose()
                    }
                )

            case "0":
                onAdDismiss()

            default:
                onAdDismiss()
            }
        } else {
            onAdDismiss()
        }
    }
}

// Giữ tham chiếu mạnh để manager không bị giải phóng trước khi ad load/show xong
enum InterAdHolder {
    static var runner: InterAdRunner?
    static var interstitialManager: InterstitialAdManager?
    static var nativeManager: NativeAdFullScreenManager?
    // Bộ đếm frequency capping theo từng key, chỉ tồn tại trong bộ nhớ (reset khi kill app)
    static var cappingCounters: [String: Int] = [:]
}

