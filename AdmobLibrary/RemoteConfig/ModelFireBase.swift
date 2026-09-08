//
//  ModelFireBase.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import Foundation

struct SplashConfig: Codable {
    let adsSplash: String
    let bannerSplash: String
    let nativeType: String
    let organic: Bool
    let units: SplashUnits

    enum CodingKeys: String, CodingKey {
        case adsSplash = "ads_splash"
        case bannerSplash = "banner_splash"
        case nativeType = "native_type"
        case organic
        case units
    }
}

struct SplashUnits: Codable {
    let inter: String
    let aoa: String
    let nativeFullscreen: String
    let native: String
    let banner: String

    enum CodingKeys: String, CodingKey {
        case inter
        case aoa
        case nativeFullscreen = "native_fullscreen"
        case native
        case banner
    }
}


struct BannerNativeConfig: Codable {
    let adsType: String
    let nativeType: String
    let organic: Bool
    let units: BannerNativeUnits

    enum CodingKeys: String, CodingKey {
        case adsType = "ads_type"
        case nativeType = "native_type"
        case organic
        case units
    }
}

struct BannerNativeUnits: Codable {
    let banner: String
    let bannerCollap: String
    let native: String
    let bannerReload: String

    enum CodingKeys: String, CodingKey {
        case banner
        case bannerCollap = "banner_collap"
        case native
        case bannerReload = "banner_reload"
    }
}


struct InterConfig: Codable {
    let type: String
    let count: String
    let organic: Bool
    let units: InterUnits
}

struct InterUnits: Codable {
    let inter: String
    let native: String
}


struct NativePreloadConfig: Codable {
    let type: String
    let organic: Bool
    let units: NativePreloadUnits
}

struct NativePreloadUnits: Codable {
    let native: String
}
