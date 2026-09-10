//
//  AdmobLibraryApp.swift
//  AdmobLibrary
//
//  Created by Tien Nguyen on 8/7/26.
//

import SwiftUI
import Combine
import FirebaseCore
import FirebaseAnalytics
import FacebookCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        // Facebook SDK
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        // Firebase Message
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
 
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.shared.activateApp()
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNs registration failed:", error)
    }

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("🔥 FCM TOKEN:")
        print(fcmToken ?? "nil")
    }
    
    // App đang foreground vẫn hiện notification
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler:
                @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([
                .banner,
                .list,
                .sound,
                .badge
            ])
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
