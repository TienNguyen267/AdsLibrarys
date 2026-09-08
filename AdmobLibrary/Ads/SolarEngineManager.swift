//
//  SolarEngineManager.swift
//  ReverseAudioIOS
//
//  Created by Tien Nguyen on 29/10/25.
//

import SolarEngineSDK

 
final class SolarEngineManager {
    
    static let shared = SolarEngineManager()
    
    private init() {}
    
    func setupSolarEngine(key : String) {
        
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
            } else {
                print("⚙️ code: \(code)")
            }
        }
        
        let config = SEConfig()
        config.logEnabled = true
        
        SolarEngineSDK.sharedInstance().preInit(withAppKey: key)
        SolarEngineSDK.sharedInstance().start(withAppKey: key, config: config)
    }
}
