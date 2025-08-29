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
    
    func fetchDevices() async {
        defer { isLoadingDeviceFetch = false }
                
        guard let jwtToken = session.token else {
            session.signOut()
            return
        }
//        print(jwtToken)
        guard let _ = session.userId else {
            session.signOut()
            return
        }

        do {
            let results = try await APIManager.shared.request(
                endpoint: .fetchDevices,
                method: "POST",
                token: jwtToken
            )
            
            if case let .fetchDevices(deviceList) = results {
                await MainActor.run {
                    devices = deviceList
                }
            }
            
        } catch {
            print("Error:", error)
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
            return
        }
        guard let _ = session.userId else {
            isLoading = false
            session.signOut()
            return
        }
        
        do {
            let _ = try await APIManager.shared.request(
                endpoint: .updateDevice,
                method: "POST",
                payload: [
                    "deviceId": deviceId,
                    "field": field,
                    "value": value
                ],
                token: jwtToken
            )
            
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
            print("Error:", error)
        }
        isLoading = false
    }
    
    func reportIssue(topic: String, message: String) async {
        isLoading = true
                
        guard let index = selectedDeviceIndex, index < devices.count else {
            isLoading = false
            return
        }
        let deviceId = devices[index].deviceId
        guard let jwtToken = session.token else {
            isLoadingDeviceFetch = false
            session.signOut()
            return
        }
        guard let _ = session.userId else {
            isLoading = false
            session.signOut()
            return
        }
        
        do {
            let _ = try await APIManager.shared.request(
                endpoint: .submitReport,
                method: "POST",
                payload: [
                    "deviceId": deviceId,
                    "topic": topic,
                    "message": message
                ],
                token: jwtToken,
            )
        } catch {
            print("Error:", error)
        }
        isLoading = false
    }
}

#Preview {
    HomeView().environmentObject(SessionManager())
}
