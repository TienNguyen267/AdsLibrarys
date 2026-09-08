//
//  PaidEventHandlerManager.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 29/10/25.
//

import Foundation
import GoogleMobileAds
import SolarEngineSDK

class PaidEventHandlerManager {
    static let shared = PaidEventHandlerManager()
    func getPaidEventHandler(dataPaidEvent: AdValue, typeAds: TypeAds, aoa: AppOpenAd? = nil, native: NativeAd? = nil, inter: InterstitialAd? = nil, banner: BannerView? = nil, reward: RewardedAd? = nil, rewardedInterstitial: RewardedInterstitialAd? = nil, adUnit: String) {
        var adSourceName: String?
        var adSourceId: String?
        var responseInfo: ResponseInfo?

        switch typeAds {
        case .nativeAds:
            responseInfo = native?.responseInfo
            let loadedAdNetworkResponseInfo = responseInfo?.loadedAdNetworkResponseInfo
            adSourceName = loadedAdNetworkResponseInfo?.adSourceName
            adSourceId   = loadedAdNetworkResponseInfo?.adSourceID ?? "unknown"
        case .bannerAds:
            responseInfo = banner?.responseInfo
            let loadedAdNetworkResponseInfo = responseInfo?.loadedAdNetworkResponseInfo
            adSourceName = loadedAdNetworkResponseInfo?.adSourceInstanceName
            adSourceId   = loadedAdNetworkResponseInfo?.adSourceID ?? "unknown"
        case .aoa:
            responseInfo = aoa?.responseInfo
            let loadedAdNetworkResponseInfo = responseInfo?.loadedAdNetworkResponseInfo
            adSourceName = loadedAdNetworkResponseInfo?.adSourceInstanceName
            adSourceId   = loadedAdNetworkResponseInfo?.adSourceID ?? "unknown"
        case .interAds:
            responseInfo = inter?.responseInfo
            let loadedAdNetworkResponseInfo = responseInfo?.loadedAdNetworkResponseInfo
            adSourceName = loadedAdNetworkResponseInfo?.adSourceInstanceName
            adSourceId   = loadedAdNetworkResponseInfo?.adSourceID ?? "unknown"
        case .rewardAds:
            responseInfo = reward?.responseInfo ?? rewardedInterstitial?.responseInfo
            let loadedAdNetworkResponseInfo = responseInfo?.loadedAdNetworkResponseInfo
            adSourceName = loadedAdNetworkResponseInfo?.adSourceInstanceName
            adSourceId   = loadedAdNetworkResponseInfo?.adSourceID ?? "unknown"
        }
        let value = dataPaidEvent.value
        print("value Ads \(typeAds.rawValue) \(value)")
        _ = dataPaidEvent.precision
        let currencyCode = dataPaidEvent.currencyCode
 
        
        let attribute = SEAdImpressionEventAttribute()
                attribute.adNetworkPlatform = adSourceName ?? "unknown"
                attribute.adNetworkAppID = adSourceId ?? "unknown"
        if let native = native {
            if native.mediaContent.hasVideoContent {
                attribute.adType = SolarEngineAdType.nativeVideo
            } else {
                attribute.adType = SolarEngineAdType.native
            }
        } else {
            attribute.adType = typeAds.typeNumber
        }
        attribute.adNetworkPlacementID = adUnit
        attribute.currency = currencyCode
        attribute.ecpm = Double(truncating: dataPaidEvent.value) * 1000 // ecpm: Giá trị quảng cáo trên mỗi 1000 lượt hiển thị
        attribute.mediationPlatform = "admob"
        attribute.rendered = true
        
        SolarEngineSDK.sharedInstance().trackAdImpression(withAttributes: attribute)

        TenjinManager.trackImpression(
            value: dataPaidEvent,
            adUnitID: adUnit,
            responseInfo: responseInfo
        )
 
    }
}
