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

public class NativeHolderAdmob: ObservableObject {
    
    @Published public var nativeAd: NativeAd?
    @Published public var isLoading: Bool = false
    
    public let adsID: String

    // MARK: - Init
    public init(adUnitID: String) {
        self.adsID = adUnitID
        print("🔥 NativeHolderAdmob initialized with ID: \(adsID)")
    }
}

