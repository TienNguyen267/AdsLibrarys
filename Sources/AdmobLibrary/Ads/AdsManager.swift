//
//  AdsManager.swift
//  Mahjong
//
//  Created by Tien Nguyen on 7/4/26.
//

final public class AdsManager {
    static public let shared = AdsManager()
    
    private init() {}
    
    /// true nếu đang có bất kỳ ads nào hiển thị
    public var isShowingAd: Bool = false
}
