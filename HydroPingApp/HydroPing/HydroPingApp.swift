//
//  ProbeApp.swift
//  Probe
//
//  Created by Ramtin Mir on 6/30/25.
//

import SwiftUI
import SwiftData
import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAppCheck

@main
struct HydroPingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var session = SessionManager()

    init() {
        if let tokenData = KeychainManager.standard.read(service: "ProbeJWT", account: "userEmail"),
           let token = String(data: tokenData, encoding: .utf8),
           let userId = UserDefaults.standard.string(forKey: "userId"),
           let email = UserDefaults.standard.string(forKey: "userEmail") {
            session.signIn(token: token, userId: userId, email: email)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    HomeView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(session)
            .onChange(of: session.userId) { _, newId in
                if newId != nil {
                    DispatchQueue.main.async {
                        NotificationManager.shared.requestAuthorization()
                    }
                }
            }

            .background(.white)
        }
    }
}
