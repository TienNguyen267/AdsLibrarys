//
//  RemoteConfigManager.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 14/10/25.
//
import Foundation
import FirebaseRemoteConfig

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    private init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 giờ
        remoteConfig.configSettings = settings
    }
    
    func initRemoteConfig(defaults: [String: NSObject], onComplete: @escaping @MainActor @Sendable () -> Void) {
        // Đặt giá trị mặc định
        remoteConfig.setDefaults(defaults)
        
        // Lắng nghe cập nhật realtime
        remoteConfig.addOnConfigUpdateListener { [weak self] update, error in
            if let error = error {
                print("❌ RemoteConfig update error: \(error.localizedDescription)")
                return
            }
            guard let update = update else { return }
            
            print("✅ RemoteConfig updated keys: \(update.updatedKeys)")
            Task { @MainActor [weak self] in
                self?.remoteConfig.activate { _, _ in
                    Task { @MainActor in
                        onComplete()
                    }
                }
            }
        }
        
        // Fetch & Activate
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                print("❌ RemoteConfig fetch error: \(error.localizedDescription)")
                return
            }
            
            if status == .successFetchedFromRemote || status == .successUsingPreFetchedData {
                print("✅ RemoteConfig fetched and activated")
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    onComplete()
                }
            } else {
                print("⚠️ RemoteConfig fetch status: \(status.rawValue)")
            }
        }
    }
    
    func getValue(forKey key: String) -> String {
        let value = remoteConfig.configValue(forKey: key).stringValue
        print("==FireBaseConfig== getValue: \(key) = \(value)")
        return value
    }
    
    func getValue<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        let json = remoteConfig.configValue(forKey: key).stringValue
        let data = Data(json.utf8)
        print("==FireBaseConfig== getValue: \(key) = \(String(describing: try? JSONDecoder().decode(T.self, from: data)))")
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
