//
//  SolarEngineManager.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 29/10/25.
//

import SolarEngineSDK

 
final public class SolarEngineManager {
    
    static public let shared = SolarEngineManager()
    
    private init() {}
    
    public func setupSolarEngine(key : String) {
        
        SolarEngineSDK.sharedInstance().setInitCompletedCallback { code in
            if code == 0 {
                print("✅ SolarEngineSDK initialized successfully: \(key)")
            } else {
                print("❌ Error for initializing SolarEngineSDK: \(code) \(key)")
            }
        }
        
        SolarEngineSDK.sharedInstance().setAttributionCallback { code, attributionData in
            if code == 0 {
                print("⚙️ attributionData: \(String(describing: attributionData))")
                Common.isOrganic = self.checkOrganic(attributionData)
            } else {
                print("⚙️ code: \(code)")
            }
        }
        
        let config = SEConfig()
        config.logEnabled = true
        
        SolarEngineSDK.sharedInstance().preInit(withAppKey: key)
        SolarEngineSDK.sharedInstance().start(withAppKey: key, config: config)
    }
    
    func checkOrganic(_ data: [AnyHashable: Any]?) -> Bool {
        guard let data = data else {
            return false
        }

        let channelName = (data["channel_name"] as? String ?? "").lowercased()
        let channelId = data["channel_id"] as? String

        let isOrganic = channelName == "organic" || channelId == "-1"

        return isOrganic
    }
}
