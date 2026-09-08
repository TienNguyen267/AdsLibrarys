//
//  NativePreload.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 17/7/26.
//

import Foundation
import SwiftUI
import Combine

@ViewBuilder
func nativeView(
    configKey: String,
    onAdLoaded: (() -> Void)? = nil,
    onAdFailedToLoad: ((Error) -> Void)? = nil
) -> some View {
    
    if let native = RemoteConfigManager.shared.getValue(forKey: configKey, as: NativePreloadConfig.self) {
        switch native.type {
        case "1":
            NativeAdContainer(
                adUnitID: native.units.native,
                onAdLoaded: { _ in onAdLoaded?() },
                onAdFailedToLoad: onAdFailedToLoad
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity)
            .background(Color.white)

        case "2":
            NativeSmallPlayAdContainer(
                adUnitID: native.units.native,
                onAdLoaded: { _ in onAdLoaded?() },
                onAdFailedToLoad: onAdFailedToLoad
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity)
            .background(Color.white)

        case "3":
            NativeSmallBannerAdContainer(
                adUnitID: native.units.native,
                onAdLoaded: { _ in onAdLoaded?() },
                onAdFailedToLoad: onAdFailedToLoad
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity)
            .background(Color.white)

        case "4":
            NativeCollapAdContainer(
                adUnitID: native.units.native,
                onAdLoaded: { _ in onAdLoaded?() },
                onAdFailedToLoad: onAdFailedToLoad
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity)
            .background(Color.white)

        default:
            EmptyView()
        }
    } else {
        EmptyView()
    }
    
}
