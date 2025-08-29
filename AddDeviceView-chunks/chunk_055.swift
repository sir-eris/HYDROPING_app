//
//  AddDeviceView.swift
//  Probe
//
//  Created by Ramtin Mir on 7/1/25.
//

import SwiftUI
import WidgetKit
import CoreLocation
import SystemConfiguration.CaptiveNetwork


struct AddDeviceView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var session: SessionManager
    
    @State private var statusMessage: String = "Follow the steps and connect to the Probe's Wi-Fi from ."
    @State private var statusStep: String = "1"
    @State private var currentPage = 0
    @State private var isLoading = false
    @State private var showWifiForm = false
    @State private var currentSSID: String = ""
    @State private var wifiName = "ATTXSkQkMQ" //ATTXSkQkMQ My_Home_Wi-Fi_Name
    @State private var wifiPassword = "nfwtdsd#i#=7" //nfwtdsd#i#=7
    @State private var deviceId: String = ""
    @State private var deviceToken: String = ""
    @State private var deviceHVersion: String = ""
    @State private var deviceFVersion: String = ""
    
    let steps: [Step] = [
        Step(id: 0, title: "Activate Setup Mode", description: "Shake your probe vigoresly to set it into setup mode and turn on its Wi-Fi for 15 minutes.", imageURL: "setup_1"),
        Step(id: 1, title: "Connect to Probe's Wi-Fi", description: "Open your iPhone’s Settings > Wi-Fi and connect to the network named `HydroPing-Wi-Fi`.", imageURL: "setup_2"),
        Step(id: 2, title: "Connect Probe to Your Wi-Fi", description: "Return to this app after the connection is complete to enter your Wi-Fi credentials and tap `Connect to Wi-Fi`.", imageURL: "setup_3"),
        Step(id: 3, title: "Wait A Few Seconds", description: "The probe will disconnect its own Wi-Fi to join your home network and continues to register itself.", imageURL: "setup_4"),
        Step(id: 4, title: "All Set!", description: "Once connected, insert the probe into your pot and tap `Complete Setup`. The probe will appear in your device list automatically.", imageURL: "setup_5")
    ]

    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(steps) { step in
                    StepView(step: step).tag(step.id)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 500)
            
            Spacer()
            
            VStack {
                if showWifiForm {
                    VStack(spacing: 12) {
                        Text("\(statusStep)/3")
                            .fontWeight(.regular)
                            .foregroundStyle(.gray)
                            .transition(.opacity)
                            .id(statusStep)
                            .animation(.easeIn(duration: 0.4), value: statusStep)
                        
                        TextField("Wifi Name", text: $wifiName)
                            .keyboardType(.default)
                            .textContentType(.username)
                            .font(.subheadline)
                            .padding(15)
                            .background(.ultraThinMaterial)
                            .cornerRadius(22)
                            .autocapitalization(.none)
                        
                        SecureField("Wifi Password", text: $wifiPassword)
                            .keyboardType(.default)
                            .textContentType(.password)
                            .font(.subheadline)
                            .padding(15)
                            .background(.ultraThinMaterial)
                            .cornerRadius(22)
                        
                        
                        GlassButton(title: "Connect to Wi-Fi") {
                            Task { await sendCredentialsToESP() }
                        }
                        .disabled(isLoading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    VStack (spacing: 24) {
                        Text("\(statusStep)/3")
                            .fontWeight(.regular)
                            .foregroundStyle(.gray)
                            .transition(.opacity)
                            .id(statusStep)
                            .animation(.easeIn(duration: 0.4), value: statusStep)
                        
                        if (statusMessage.contains("Follow the steps and connect to the Probe's Wi-Fi from .")) {
                            VStack {
                                Text("Settings > Wi-Fi > HydroPing-Wi-Fi")
                                    .foregroundColor(.blue)
                        }
                            .font(.headline)
                            .transition(.opacity)
                            .id(statusMessage)
                            .animation(.easeInOut(duration: 0.4), value: statusMessage)
                            .multilineTextAlignment(.center)
                            
                        } else {
                            Text(statusMessage)
                                .font(.headline)
                                .transition(.opacity)
                                .id(statusMessage)
                                .animation(.easeInOut(duration: 0.4), value: statusMessage)
                                .multilineTextAlignment(.center)
                        }
                        
                        if (statusMessage == "Follow the steps and connect to the Probe's Wi-Fi from .") {
                            Button("Check Connection") {
                                Task {
                                    await checkSSID()
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Having an issue connecting to your probe...") {
                            Button("Check Connection") {
                                Task {
                                    await checkSSID()
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Syncing seems to have run into an issue...") {
                            Button("Sync Again") {
                                Task {
                                    await retreiveDeviceInfo()
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Registeration seems to have run into an issue...") {
                            Button("Sync Again") {
                                Task {
                                    await registerDevice()
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Registeration seems not completed properly...") {
                            Button("Retry Registration") {
                                Task {
                                    await registerDevice()
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Connecting probe to the web faced an issue...") {
                            Button("Try Connecting Again") {
                                Task {
                                    await sendCredentialsToESP()
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Successfully connected your probe to the web.") {
                            Button("Complete Setup") {
                                withAnimation {
                                    statusMessage = "Setup completed successfully."
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        } else if (statusMessage == "Setup completed successfully.") {
                            Button("Connect Another Probe") {
                                withAnimation {
                                    statusStep = "1"
                                    statusMessage = "Follow the steps and connect to the Probe's Wi-Fi from ."
                                }
                            }
                            .underline()
                            .foregroundStyle(Color(hex: "#008000"))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 24)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal)
        }
        .onAppear {
            requestLocationPermission()
        }
        .navigationTitle("Add New Probe")
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
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
                        
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    struct Step: Identifiable {
        let id: Int
        let title: String
        let description: String
        let imageURL: String
    }

    struct StepView: View {
        let step: Step
        
        var body: some View {
            VStack {
                VStack {
                Image(step.imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 270)
                    .clipShape(
                        RoundedCorner(radius: 32, corners: [.topLeft, .topRight])
                    )
                    .clipped()
                                        
                    VStack(spacing: 12) {
                        Text(step.title)
                            .font(.title2)
                            .bold()
                        
                        Text(step.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 120)
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 430)
                .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                        )
                .padding(.top)
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    private func checkSSID() async {
        if let ssid = getWiFiSSID(), ssid.contains("HydroPing") {
            currentSSID = ssid
            withAnimation {
                statusMessage = "Syncing with Probe..."
            }
            await retreiveDeviceInfo()
        } else {
            withAnimation {
                statusMessage = "Having an issue connecting to your probe..."
            }
        }
    }
    
    private func getWiFiSSID() -> String? {
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary?,
                   let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                    return ssid
                }
            }
        }
        return nil
    }

    func requestLocationPermission() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
    }
    
    struct DeviceInfo: Decodable {
        let deviceId: String
        let hardwareVersion: String
