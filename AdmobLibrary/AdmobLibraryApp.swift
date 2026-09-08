//
//  AdmobLibraryApp.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
       
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
}

@main
struct AdmobLibraryApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var hasEnteredBackground = false
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .onChange(of: scenePhase,) {_, newPhase in
            switch newPhase {
            case .background:
                print("🔴 App moved to background")
                hasEnteredBackground = true
                
            case .active:
                print("🟢 App became active")
                
                if hasEnteredBackground {
                    print("🔥 Resume từ background → show ad")
                    OnResumeManager.shared.showAdIfAvailable()
                    
                    hasEnteredBackground = false
                }
                
            default:
                break
            }
        }
    }
}
