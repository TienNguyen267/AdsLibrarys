//
//  NativeHolderAdmob.swift
//  ImmersiveReadyIOS
//
//  Created by Tien Nguyen on 2/12/25.
//

import Foundation
import GoogleMobileAds
import Combine

import SwiftUI

class NativeHolderAdmob: ObservableObject {
    
    @Published var nativeAd: NativeAd?
    @Published var isLoading: Bool = false
    
    let adsID: String

    // MARK: - Init
    init(adUnitID: String) {
        self.adsID = adUnitID
        print("🔥 NativeHolderAdmob initialized with ID: \(adsID)")
    }
}

