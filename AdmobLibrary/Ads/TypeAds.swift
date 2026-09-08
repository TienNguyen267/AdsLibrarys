//
//  TypeAds.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 29/10/25.
//

import Foundation
import SolarEngineSDK

enum TypeAds: String {
    case nativeAds = "NATIVE_ADS"
    case bannerAds = "BANNER_ADS"
    case aoa = "AOA_ADS"
    case interAds = "INTER_ADS"
    case rewardAds = "REWARD_ADS"
 
    
    var typeNumber: SolarEngineAdType {
            switch self {
            case .nativeAds:
                return SolarEngineAdType.nativeVideo
            case .bannerAds:
                return SolarEngineAdType.banner
            case .aoa:
                return SolarEngineAdType.splash
            case .interAds:
                return SolarEngineAdType.interstitial
            case .rewardAds:
                return SolarEngineAdType.rewardVideo
            }
        }
 
}
