//
//  DebugModeManager.swift
//  ImmersiveReadyIOS
//
//  Created by Tien Nguyen on 3/12/25.
//
//
//  DebugModeManager.swift
//
//  Kết hợp App Store + Firebase Remote Config để set Common.isDebug
//
//  Logic mong muốn:
//  - App chưa có trên Store:
//      + Chưa được duyệt (chưa có entry trên App Store) → isDebug = true
//      + Khi được duyệt lần đầu (đã có trên Store, version khớp) → isDebug = false
//
//  - App đã có trên Store:
//      + Đang chạy bản mới hơn bản live (cv > sv) → isDebug = true  (bản mới đang chờ duyệt / test)
//      + Đang chạy đúng bản live (cv == sv)      → isDebug = false (bản đã duyệt, public)
//      + Đang chạy bản cũ hơn (cv < sv)          → isDebug = false (user chưa update nhưng bản này vẫn là bản đã từng duyệt)
//
//  => isDebug_storeLogic =
//      - true  nếu:   storeVersion == nil  (app chưa có trên Store)
//                  hoặc currentVersion > storeVersion (bản mới hơn bản live)
//      - false nếu:   currentVersion <= storeVersion (đang chạy bản đã duyệt hoặc cũ)
//
//  Sau đó combine với Remote Config:
//      isDebug_rc = RemoteConfig["isDebug"].boolValue
//      Common.isDebug = isDebug_storeLogic || isDebug_rc
//

//| Tình huống                  | App Store     | RC isDebug | isDebug_storeLogic | final | Giải thích                 |
//| --------------------------- | ------------- | ---------- | ------------------ | ----- | -------------------------- |
//| App chưa có trên store      | none          | 0          | true               | true  | test build trước khi duyệt |
//| App chưa có trên store      | none          | 1          | true               | true  | RC ép cũng true            |
//| App đang live               | same version  | 0          | false              | false | bản đã duyệt               |
//| App đang live + RC bật      | same version  | 1          | false              | true  | RC override                |
//| Upload bản mới chờ duyệt    | local > store | 0          | true               | true  | bản chờ duyệt              |
//| Upload bản mới nhưng RC bật | local > store | 1          | true               | true  | vẫn true                   |


import Foundation
import FirebaseRemoteConfig

final class DebugModeManager {
    
    static let shared = DebugModeManager()
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public API
    
    /// Gọi hàm này sau khi FirebaseApp.configure()
    /// Ví dụ: trong AppDelegate hoặc init() của SwiftUI App
    ///
    /// Combine App Store logic + RemoteConfig logic (từ ngoài truyền vào)
    func configureDebugFlag(
        rcValue: Bool,                     // ⬅️ lấy từ RemoteConfigManager
        completion: ((Bool) -> Void)? = nil
    ) {
        let group = DispatchGroup()
        
        var isDebugStoreLogic: Bool = false
        let isDebugRemoteConfig: Bool = rcValue   // ⬅️ lấy trực tiếp từ caller
        
        // 1) Lấy từ App Store
        group.enter()
        fetchIsDebugFromAppStore { value in
            isDebugStoreLogic = value
            group.leave()
        }
        
        // 2) Combine
        group.notify(queue: .main) {
            let finalDebug = isDebugStoreLogic || isDebugRemoteConfig
            Common.isDebug = finalDebug
            
            print("""
            🐞 DebugModeManager 
            - isDebug_storeLogic = \(isDebugStoreLogic)
            - isDebug_rc = \(isDebugRemoteConfig)
            - final = \(finalDebug)
            """)
            
            completion?(finalDebug)
        }
    }
    
    // MARK: - App Store logic
    
    /// Tính isDebug_storeLogic dựa trên version trên App Store
    ///
    /// - isDebug_storeLogic = true nếu:
    ///     * App chưa có trên Store (không có storeVersion)
    ///     * Hoặc currentVersion > storeVersion (bản mới đang chờ duyệt / test)
    /// - isDebug_storeLogic = false nếu:
    ///     * currentVersion <= storeVersion (đang chạy bản đã duyệt hoặc cũ hơn)
    private func fetchIsDebugFromAppStore(completion: @escaping (Bool) -> Void) {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            print("❌ Không lấy được bundleId")
            completion(false)
            return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&_=\(timestamp)") else {
            print("❌ URL lookup App Store không hợp lệ")
            completion(false)
            return
        }
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        print("ℹ️ Current app version: \(currentVersion)")
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Error / network fail
            if let error = error {
                print("❌ App Store lookup error:", error.localizedDescription)
                // Không gọi được App Store → coi như chưa có thông tin → cho debug = true cho an toàn dev
                completion(true)
                return
            }
            
            guard let data = data else {
                print("❌ App Store lookup: no data")
                // Không có data → tương tự: cho true để không khóa debug khi dev
                completion(true)
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                guard
                    let json = jsonObject as? [String: Any],
                    let results = json["results"] as? [[String: Any]]
                else {
                    print("❌ App Store lookup: JSON format không đúng")
                    completion(true)
                    return
                }
                
                // App chưa có trên store lần nào
                if results.isEmpty {
                    print("ℹ️ App chưa có trên App Store → isDebug_storeLogic = true")
                    completion(true)
                    return
                }
                
                guard let first = results.first,
                      let storeVersion = first["version"] as? String
                else {
                    print("❌ App Store lookup: không lấy được version")
                    completion(true)
                    return
                }
                
                print("ℹ️ App Store version: \(storeVersion)")
                
                let compareResult = currentVersion.compare(storeVersion, options: .numeric)
                
                let isDebugStoreLogic: Bool
                
                switch compareResult {
                case .orderedDescending:
                    // currentVersion > storeVersion
                    // → app đang chạy bản mới hơn bản live (bản mới chờ duyệt / test)
                    isDebugStoreLogic = true
                case .orderedSame, .orderedAscending:
                    // currentVersion == storeVersion  → bản đang live, đã duyệt
                    // currentVersion < storeVersion   → đang chạy bản cũ hơn (cũng đã từng duyệt)
                    isDebugStoreLogic = false
                @unknown default:
                    isDebugStoreLogic = false
                }
                
                print("📦 isDebug_storeLogic (from App Store logic) = \(isDebugStoreLogic)")
                completion(isDebugStoreLogic)
                
            } catch {
                print("❌ JSON parse App Store lookup error:", error.localizedDescription)
                // Parse lỗi → cho true để dev/debug không bị khóa
                completion(true)
            }
        }.resume()
    }
    
    // MARK: - Remote Config logic
    
    /// Lấy isDebug từ Remote Config
    private func fetchIsDebugFromRemoteConfig(completion: @escaping (Bool) -> Void) {
        let rc = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // dev: fetch mọi lần
        #else
        settings.minimumFetchInterval = 3600 // production: 1h
        #endif
        rc.configSettings = settings
        
        // Default nếu chưa set trên console
        let defaults: [String: NSObject] = [
            "isDebug" : false as NSObject
        ]
        rc.setDefaults(defaults)
        
        rc.fetchAndActivate { status, error in
            if let error = error {
                print("❌ RemoteConfig fetchAndActivate error:", error.localizedDescription)
                let value = rc["isDebug"].boolValue
                print("📡 RC isDebug (fallback after error) = \(value)")
                completion(value)
                return
            }
            
            let value = rc["isDebug"].boolValue
            print("📡 RC isDebug = \(value), status = \(status.rawValue)")
            completion(value)
        }
    }
}
