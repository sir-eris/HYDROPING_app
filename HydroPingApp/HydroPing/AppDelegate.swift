//
//  AppDelegate.swift
//  HydroPing
//
//  Created by Ramtin Mir on 7/14/25.
//

import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAppCheck


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        FirebaseApp.configure()
        
//        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
//           let options = FirebaseOptions(contentsOfFile: filePath) {
//            FirebaseConfiguration.shared.setLoggerLevel(.min)
//            FirebaseApp.configure(options: options)
//        } else {
//            print("❌ Failed to load Firebase options.")
//        }
        
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
//        print("📲 Device Token: \(tokenString)")
        
        NotificationManager.shared.registerDeviceToken(deviceToken)
        guard let userId = SessionManager.shared.userId else {
            print("⚠️ No userId available, cannot send token to backend")
            return
        }
        
        Task {
            await NotificationManager.shared.sendTokenToBackend(userId: SessionManager.shared.userId!, token: SessionManager.shared.token!)
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for notifications:", error)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        print("GIDSignIn")
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // Receive notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle tap on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle deep link or app action
        completionHandler()
    }
}


class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}
