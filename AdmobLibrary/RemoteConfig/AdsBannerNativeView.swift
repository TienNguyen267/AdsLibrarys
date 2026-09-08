//
//  AdsBannerNativeView.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import Foundation
import SwiftUI
import Combine

@ViewBuilder
func adsBannerNativeView(
    configKey: String,
    isClose : Bool = false,
    onAdLoaded: (() -> Void)? = nil,
    onAdFailedToLoad: ((Error) -> Void)? = nil
) -> some View {
    if let banner = RemoteConfigManager.shared.getValue(forKey: configKey, as: BannerNativeConfig.self) {
        switch banner.adsType {
        case "1":
            BannerAdViewWithShimmer(
                adUnitID: banner.units.banner,
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad
            )

        case "2":
            BannerCollapsibleAdView(
                adUnitID: banner.units.bannerCollap,
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad
            )

        case "3":
            switch banner.nativeType {
            case "1":
                NativeAdContainer(
                    adUnitID: banner.units.native,
                    onAdLoaded: { _ in onAdLoaded?() },
                    onAdFailedToLoad: onAdFailedToLoad
                )
                .ignoresSafeArea()
                .frame(maxWidth: .infinity)
                .background(Color.white)

            case "2":
                NativeSmallPlayAdContainer(
                    adUnitID: banner.units.native,
                    onAdLoaded: { _ in onAdLoaded?() },
                    onAdFailedToLoad: onAdFailedToLoad
                )
                .ignoresSafeArea()
                .frame(maxWidth: .infinity)
                .background(Color.white)

            case "3":
                NativeSmallBannerAdContainer(
                    adUnitID: banner.units.native,
                    onAdLoaded: { _ in onAdLoaded?() },
                    onAdFailedToLoad: onAdFailedToLoad
                )
                .ignoresSafeArea()
                .frame(maxWidth: .infinity)
                .background(Color.white)

            case "4":
                Group {
                    if isClose {
                        NativeCollapCloseAdContainer(
                            adUnitID: banner.units.native,
                            onAdLoaded: { _ in onAdLoaded?() },
                            onAdFailedToLoad: onAdFailedToLoad
                        )
                    } else {
                        NativeCollapAdContainer(
                            adUnitID: banner.units.native,
                            onAdLoaded: { _ in onAdLoaded?() },
                            onAdFailedToLoad: onAdFailedToLoad
                        )
                    }
                }
                .ignoresSafeArea()
                .frame(maxWidth: .infinity)
                .background(Color.white)

            default:
                EmptyView()
            }

        default:
            EmptyView()
        }
    } else {
        EmptyView()
    }
}
