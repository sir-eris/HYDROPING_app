//
//  NotificationManager.swift
//  Probe
//
//  Created by Ramtin Mir on 7/2/25.
//

import Foundation
import UserNotifications
import UIKit


class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    private override init() { super.init() }
    
    var deviceToken: String?
    
    func requestAuthorization() {
        Task { @MainActor in
            let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
//            print("🔔 Permission granted: \(granted ?? false)")

            if granted == true {
//                print("📬 Registering for remote notifications")
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    
    func registerDeviceToken(_ token: Data) {
        let tokenParts = token.map { String(format: "%02.2hhx", $0) }
        self.deviceToken = tokenParts.joined()
//        print("Device Token: \(self.deviceToken!)")
    }
    
    func clearAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    func sendTokenToBackend(userId: String, token: String) async {
        guard let tokenString = deviceToken,
            let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/setupNitification")
        else {
//            print( "Invalid URL")
            return
        }
        
        let body: [String: String] = [
            "tokenString": tokenString
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
//                print("Server error or invalid response")
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Status: \(httpResponse.statusCode)")
//                }
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("Response: \(jsonString)")
//                }
                return
            }
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let newToken = jsonObject["newToken"] as? String {
                
                await SessionManager.shared.renewToken(token: newToken)
            }
            
        } catch {
//            print("Failed to report issue: \(error.localizedDescription)")
        }
    }
    
//    func scheduleLocal(
//        title: String,
//        body: String,
//        delay: TimeInterval = 1,
//        sound: UNNotificationSound = .default
//    ) {
//        let content = UNMutableNotificationContent()
//        content.title = title
//        content.body  = body
//        content.sound = sound
//        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Notification error:", error.localizedDescription)
//            } else {
//                print("Notification scheduled.")
//            }
//        }
//    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {}


//NotificationManager.shared.scheduleLocal(
//    title: "Probe Alert",
//    body: "A probe just went offline.",
//    delay: 3
//)



