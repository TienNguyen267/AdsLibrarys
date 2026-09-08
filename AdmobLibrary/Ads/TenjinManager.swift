//
//  TenjinManager.swift
//  Shikaku
//
//  Created by Tien Nguyen on 10/7/26.
//

import Foundation
import GoogleMobileAds

final class TenjinManager {

    static let shared = TenjinManager()

    private var isInitialized = false

    private init() {}

    func initialize(sdkKey: String) {
        guard !isInitialized, !sdkKey.isEmpty else { return }

        TenjinSDK.getInstance(sdkKey)

        #if DEBUG
        TenjinSDK.debugLogs()
        #endif

        TenjinSDK.connect()
        isInitialized = true
    }

    static func trackImpression(
        value: AdValue,
        adUnitID: String,
        responseInfo: ResponseInfo? = nil
    ) {
        let json: [String: Any] = [
            "ad_unit_id": adUnitID,
            "value_micros": value.value,
            "currency_code": value.currencyCode,
            "response_id": responseInfo?.responseIdentifier ?? "",
            "mediation_adapter_class_name":
                responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "",
            "precision_type": value.precision.rawValue
        ]

        guard
            let data = try? JSONSerialization.data(withJSONObject: json),
            let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        TenjinSDK.adMobImpression(fromJSON: jsonString)
    }
}
