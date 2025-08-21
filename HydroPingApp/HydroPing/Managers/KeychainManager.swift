//
//  KeychainHelper.swift
//  Probe
//
//  Created by Ramtin Mir on 6/30/25.
//
import Foundation
import Security

final class KeychainManager {
    static let standard = KeychainManager()

    private init() {}

    // MARK: - Save
    func save(_ data: Data, service: String, account: String, accessGroup: String? = nil) {
        // Create query
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    func save<T: Codable>(_ item: T, service: String, account: String, accessGroup: String? = nil) {
        do {
            let data = try JSONEncoder().encode(item)
            save(data, service: service, account: account, accessGroup: accessGroup)
        } catch {
//            print("🔐 Failed to encode item for keychain: \(error)")
        }
    }

    // MARK: - Read

    func read(service: String, account: String, accessGroup: String? = nil) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        return result as? Data
    }

    func read<T: Codable>(_ type: T.Type, service: String, account: String, accessGroup: String? = nil) -> T? {
        guard let data = read(service: service, account: account, accessGroup: accessGroup) else {
            return nil
        }

        do {
            let item = try JSONDecoder().decode(type, from: data)
            return item
        } catch {
//            print("🔐 Failed to decode item from keychain: \(error)")
            return nil
        }
    }

    // MARK: - Delete

    func delete(service: String, account: String, accessGroup: String? = nil) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        SecItemDelete(query as CFDictionary)
    }
}
