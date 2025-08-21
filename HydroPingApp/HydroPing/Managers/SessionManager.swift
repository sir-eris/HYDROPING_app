//
//  SessionManager.swift
//  Probe
//
//  Created by Ramtin Mir on 6/30/25.
//

import Foundation
import WidgetKit


final class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published private(set) var isLoggedIn = false
    @Published private(set) var token:  String?
    @Published private(set) var userId: String?
    @Published private(set) var email:  String?
    
    private let keychainService = "token"
    private let appGroup = "group.com.erisverne.hydroping"
    private let accessGroup = "M673G6VLXY.com.erisverne.hydroping.shared"
    
    init() {
        loadSessionFromKeychain()
    }
    
    @MainActor
    func signIn(token: String, userId: String, email: String) {
        KeychainManager.standard.save(token, service: keychainService, account: email, accessGroup: accessGroup)
        UserDefaults(suiteName: appGroup)?.set(email, forKey: "userEmail")
        UserDefaults(suiteName: appGroup)?.set(userId, forKey: "userId")

        self.token = token
        self.userId = userId
        self.email = email
        self.isLoggedIn = true
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @MainActor
    func signOut() {
        if let email = UserDefaults(suiteName: appGroup)?.string(forKey: "userEmail") {
            let deleted: () = KeychainManager.standard.delete(service: keychainService, account: email, accessGroup: accessGroup)
//            print("Token deleted: \(deleted)")
        }
        UserDefaults(suiteName: appGroup)?.removeObject(forKey: "userEmail")
        UserDefaults(suiteName: appGroup)?.removeObject(forKey: "userId")
        
        token  = nil
        userId = nil
        email  = nil
        isLoggedIn = false
        
        NotificationManager.shared.clearAll()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @MainActor
    func renewToken(token: String) {
        if let email = UserDefaults(suiteName: appGroup)?.string(forKey: "userEmail") {
            let saved: () = KeychainManager.standard.save(token, service: keychainService, account: email, accessGroup: accessGroup)
//            print("Token renewd: \(token)")
        }
        
        let cleanedToken = token.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        self.token = cleanedToken
    }
    
    // MARK: ‑ Private Helpers
    private func loadSessionFromKeychain() {
        // Read token from Keychain with access group
        guard
            let savedEmail = UserDefaults(suiteName: appGroup)?.string(forKey: "userEmail"),
            let savedUserId = UserDefaults(suiteName: appGroup)?.string(forKey: "userId"),
            let tokenData = KeychainManager.standard.read(service: keychainService, account: savedEmail, accessGroup: accessGroup),
            let savedToken = String(data: tokenData, encoding: .utf8)
        else {
//            print(">>> No valid session stored in Keychain")
            isLoggedIn = false
            return
        }
                        
        self.email = savedEmail
        self.userId = savedUserId
        let cleanedToken = savedToken.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        self.token = cleanedToken
        self.isLoggedIn = true
    }
}


