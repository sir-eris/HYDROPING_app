//
//  Home.swift
//  Probe
//
//  Created by Ramtin Mir on 6/30/25.
//
import SwiftUI
import WidgetKit

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
//    @State private var devices: [Device] = sampleDevices
    @State private var devices: [Device] = []
    @State private var selectedDevice: Device?
    @State private var selectedDeviceIndex: Int? = nil
    @State private var isLoading = false
    @State private var isLoadingDeviceFetch = false
    @State private var currentPage = 0
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    Group {
                        if isLoadingDeviceFetch {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 600)
                        } else if devices.isEmpty {
                            VStack(alignment: .center, spacing: 8) {
                                Text("No Probes Found")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                Text("Connect a probe using the plus button in the top left corner.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity, minHeight: 600)
                            .padding()
                        } else {
                            VStack(spacing: 16) {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(devices.indices, id: \.self) { index in
                                        let device = devices[index]
                                        
                                        DeviceCard(device: device)
                                            .onTapGesture {
                                                selectedDeviceIndex = index
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 70)
                        }
                    }
                }
                .refreshable {
//                    isLoadingDeviceFetch = true
                    await fetchDevices()
//                    isLoadingDeviceFetch = false
                }
                Text("Pull to refresh")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.bottom, 16)
            }
            .navigationTitle("My Plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: AddDeviceView()) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .blur(radius: 1)
                                )
                                .frame(width: 39, height: 39)
                                .shadow(color: Color.white.opacity(0.2), radius: 1, x: -1, y: -1)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 1)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .regular))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .blur(radius: 1)
                                )
                                .frame(width: 39, height: 39)
                                .shadow(color: Color.white.opacity(0.2), radius: 1, x: -1, y: -1)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 1)
                            
                            Image(systemName: "person")
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .regular))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedDeviceIndex != nil },
            set: { if !$0 { selectedDeviceIndex = nil } }
        )) {
            if let index = selectedDeviceIndex {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    DeviceInfoModal(
                        device: $devices[index],
                        loading: isLoading,
                        updateAction: { field, value in
                            Task {
                                await updateDeviceInfo(field: field, value: value)
                            }
                        },
                        reportIssueAction: { topic, message in
                            Task {
                                await reportIssue(topic: topic, message: message)
                            }
                        }
                    )
                }
                .ignoresSafeArea(.all)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
            }
        }
        .task {
            isLoadingDeviceFetch = true
            await fetchDevices()
            WidgetCenter.shared.reloadAllTimelines()
            isLoadingDeviceFetch = false
        }
    }
    
    struct FetchDevicesResponse: Decodable {
        let newToken: String?
        let devices: [Device]
    }
    func fetchDevices() async {
        defer { isLoadingDeviceFetch = false }
                
        guard let jwtToken = session.token else {
            session.signOut()
//            print( "Invalid token")
            return
        }
//        print(jwtToken)
        guard let _ = session.userId else {
            session.signOut()
//            print( "Invalid userId")
            return
        }
        guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/getUserProbes") else {
//            print( "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
//                print(httpResponse.statusCode)
                if httpResponse.statusCode == 410 {
//                    print("Account deleted (410 Gone)")
                    DispatchQueue.main.async { session.signOut() }
                    return
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
//                print("Server error or invalid response")
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Status: \(httpResponse.statusCode)")
//                }
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("Response: \(jsonString)")
//                }
                
                isLoading = false
                return
            }
            
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = .iso8601
//            let results = try decoder.decode(FetchDevicesResponse.self, from: data)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)

                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date format: \(dateStr)"
                )
            }
            let results = try decoder.decode(FetchDevicesResponse.self, from: data)

            if let token = results.newToken {
                session.renewToken(token: token)
            }
            
            await MainActor.run {
                devices = results.devices
            }
            
        } catch {
//            print("Failed to fetch devices: \(error)")
        }
    }
    
    func updateDeviceInfo(field: String, value: Any) async {
        isLoading = true
        
        guard let index = selectedDeviceIndex, index < devices.count else {
            isLoading = false
            return
        }
        let deviceId = devices[index].deviceId
        guard let jwtToken = session.token else {
            isLoadingDeviceFetch = false
            session.signOut()
//            print( "Invalid token")
            return
        }
        guard let _ = session.userId else {
            isLoading = false
            session.signOut()
            return
        }
        guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/updateProbeInfo") else {
            isLoading = false
            return
        }

        let body: [String: Any] = [
            "deviceId": deviceId,
            "field": field,
            "value": value
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
//                print(httpResponse.statusCode)
                if httpResponse.statusCode == 410 {
//                    print("Account deleted (410 Gone)")
                    DispatchQueue.main.async { session.signOut() }
                    return
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
//                print("Server error or invalid response")
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Status: \(httpResponse.statusCode)")
//                }
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("Response: \(jsonString)")
//                }
                isLoading = false
                return
            }
            
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let newToken = jsonObject["newToken"] as? String {
                
                session.renewToken(token: newToken)
            }
            
            DispatchQueue.main.async {
                guard var updated = selectedDevice else {
                    isLoading = false
                    return
                }
                updated.update(field: field, value: value)
                selectedDevice = updated
                isLoading = false
            }
            
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
//            print("Failed to update device info: \(error.localizedDescription)")
            isLoading = false
        }
        
        isLoading = false
    }
    
    func reportIssue(topic: String, message: String) async {
        isLoading = true
                
        guard let index = selectedDeviceIndex, index < devices.count else {
//            print( "Invalid index")
            isLoading = false
            return
        }
        let deviceId = devices[index].deviceId
        guard let jwtToken = session.token else {
//            print( "Invalid token")
            isLoadingDeviceFetch = false
            session.signOut()
            return
        }
        guard let _ = session.userId else {
//            print( "Invalid userId")
            isLoading = false
            session.signOut()
            return
        }
        guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/submitReport") else {
//            print( "Invalid url")
            isLoading = false
            return
        }

        let body: [String: Any] = [
            "deviceId": deviceId,
            "topic": topic,
            "message": message
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
                if httpResponse.statusCode == 410 {
//                    print("Account deleted (410 Gone)")
//                TODO: elaborate more
                    DispatchQueue.main.async { session.signOut() }
                    return
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
//                print("Server error or invalid response")
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Status: \(httpResponse.statusCode)")
//                }
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("Response: \(jsonString)")
//                }
                isLoading = false
                return
            }
            
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let newToken = jsonObject["newToken"] as? String {
                
                session.renewToken(token: newToken)
            }
            
            isLoading = false
        } catch {
//            print("Failed to report issue: \(error.localizedDescription)")
            isLoading = false
        }
        
        isLoading = false
    }
}

#Preview {
    HomeView().environmentObject(SessionManager())
}
