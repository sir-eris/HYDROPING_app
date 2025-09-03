//
//  APIManager.swift
//  HydroPing
//
//  Created by Ramtin Mir on 8/29/25.
//

import Foundation

enum Endpoint: String {
    case fetchDevices = "getUserProbes"
    case updateDevice = "updateProbeInfo"
    case addProbe = "addProbe"
    case submitReport = "submitReport"
    
    var path: String { self.rawValue }
}

enum APIResult {
    case fetchDevices([Device])
    case updateDevice // nothing to return
    case addProbe([String: Any])
    case submitReport // nothing to return
}

enum APIError: Error {
    case invalidURL
    case badStatus(Int, Data?)
    case noData
    case decodingError(Error)
}

class APIManager {
    static let shared = APIManager()
    private let sessionMng = SessionManager.shared
    
    private let baseURL: String
    private let baseAPIStage: String = "default"
    private let session: URLSession
    
    private init() {
        // Could also be loaded from a .plist or Config file
        baseURL = "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/" + baseAPIStage + "/"
        session = URLSession.shared
    }
    
    // Generic API call
    func request(
        endpoint: Endpoint,
        method: String = "GET",
        payload: [String: Any]? = nil,
        token: String? = nil,
        signOutOnError: Bool = false,
        debug: Bool = false
    ) async throws -> APIResult {
        
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body
        if let payload = payload, method != "GET" {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badStatus(-1, nil) // Invalid response
        }
        
        // Debug logging
        if debug {
            if !(200..<300).contains(httpResponse.statusCode) {
                print("⚠️ Server error \(httpResponse.statusCode)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response: \(jsonString)")
                }
            }
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            if signOutOnError { await sessionMng.signOut() }
            if endpoint == .addProbe { return .addProbe(["error" : true]) }
            throw APIError.badStatus(httpResponse.statusCode, data)
        }
        
        // Token renewal
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let dict = jsonObject as? [String: Any],
           let newToken = dict["newToken"] as? String {
            await sessionMng.renewToken(token: newToken)
        }
        
        // Endpoint-specific parsing
        switch endpoint {
        case .fetchDevices:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let devices = dict["devices"] {
                let devicesData = try JSONSerialization.data(withJSONObject: devices)
                return .fetchDevices(try decoder.decode([Device].self, from: devicesData))
            }
            return .fetchDevices(try decoder.decode([Device].self, from: data))
            
        case .updateDevice:
            return .updateDevice
            
        case .addProbe:
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let dict = jsonObject as? [String: Any],
               let deviceToken = dict["deviceToken"] as? String {
                return .addProbe(["deviceToken" : deviceToken])
            }
            
            return .addProbe(["error" : true])
        case .submitReport:
            return .submitReport
        }
    }
}
