//
//  AdsManager.swift
//  Mahjong
//
//  Created by Tien Nguyen on 7/4/26.
//

final class AdsManager {
    static let shared = AdsManager()
    
    private init() {}
    
    /// true nếu đang có bất kỳ ads nào hiển thị
    var isShowingAd: Bool = false
}
