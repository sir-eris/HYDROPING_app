//
//  probe.swift
//  Probe
//
//  Created by Ramtin Mir on 7/1/25.
//

import SwiftUI
import Charts


struct Device: Identifiable, Codable {
    // Computed property
    var id: String { deviceId }
    
    // Stored properties
    let deviceId: String
    var name: String?
    var location: String?
    let status: DeviceStatus?
    var potSize: String?
    var lighting: String?
    var placement: String?
    let hardwareVersion: String?
    let firmwareVersion: String?
    var notitificationEnabled: Bool?
    let moistureHistory: [MoistureReading]
    let thresholds: [HistoryChartThreshold]?
    let nextWaterTime: String?
    
    // Computed property that returns latest reading or 0.0
    var firstMoistureValue: Double {
        if let first = moistureHistory.first {
            return status?.toString != "offline" ? Double(first.moisture) : 0.0
        }
        return 0.0
    }
    
    // Convenience method to update fields dynamically
    mutating func update(field: String, value: Any) {
        switch field {
        case "location": location = value as? String ?? ""
        case "name": name = value as? String ?? ""
        case "potSize": potSize = value as? String ?? ""
        case "lighting": lighting = value as? String ?? ""
        case "placement": placement = value as? String ?? ""
        case "notitificationEnabled": notitificationEnabled = value as? Bool ?? false
        default: break
        }
    }
}


enum DeviceStatus: String, Codable {
    case new, dry, okay, ideal, wet, offline

    var color: Color {
        switch self {
        case .new: return .purple
        case .dry: return .red
        case .okay: return .yellow
        case .ideal: return .green
        case .wet: return .blue
        case .offline: return .gray.opacity(0.1)
        }
    }

    var description: String {
        switch self {
        case .new: return "Loading"
        case .dry: return "Critical"
        case .okay: return "Moderate"
        case .ideal: return "Healthy"
        case .wet: return "Wet"
        case .offline: return "Offline"
        }
    }
    
    var longDescription: String {
        switch self {
        case .new: return "Not enough readings."
        case .dry: return "Water as soon as possible."
        case .okay: return "Plan to water soon."
        case .ideal: return "Soil moisture is ideal."
        case .wet: return "Avoid overwatering."
        case .offline: return "Confirm probe is active."
        }
    }
    
    var toString: String {
        switch self {
        case .new: return "new"
        case .dry: return "dry"
        case .okay: return "okay"
        case .ideal: return "ideal"
        case .wet: return "wet"
        case .offline: return "offline"
        }
    }
}

struct MoistureReading: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let moisture: Int
    
    private enum CodingKeys: String, CodingKey {
        case timestamp
        case moisture
    }
}

struct DeviceCard: View {
    let device: Device
    @State private var isBlinking = false

    var body: some View {
        let color = device.status?.color ?? .gray
        
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if (device.status?.toString == "offline") {
                        HStack(alignment: .center) {
                            Text(device.name?.isEmpty == false ? device.name! : "Probe")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .foregroundColor(.gray)
                                .imageScale(.medium)
                        }
                    } else {
                        Text(device.name?.isEmpty == false ? device.name! : "Probe")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    
                    if (device.status?.toString != "offline") {
                        MoistureBar(moisture: device.firstMoistureValue, maxMoisture: 100, statusColor: color)
                        
                        HStack {
                            Text(device.location?.isEmpty == false ? device.location! : "Tab to setup")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .opacity(isBlinking ? 0.5 : 1)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isBlinking)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .background(color.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(0.9), lineWidth: 3)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct MoistureBar: View {
    let moisture: Double
    let maxMoisture: Double
    let statusColor: Color

    var body: some View {
        let controlledMoisture = min(max(moisture, 5), maxMoisture)
        
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 10)
                
                Capsule()
                    .fill(statusColor)
                    .frame(
                        width: CGFloat(controlledMoisture / maxMoisture) * geometry.size.width,
                        height: 10
                    )
                    .animation(.easeInOut, value: moisture)
            }
        }
        .frame(height: 10)
        .padding(.vertical, 4)
    }
}

struct DeviceInfoModal: View {
    @Binding var device: Device
    let loading: Bool
    var updateAction: (_ field: String, _ value: Any) -> Void
    var reportIssueAction: (_ topic: String, _ message: String) -> Void
    var encodedId: String { encodeMAC(device.deviceId)! }
    
    @State private var showRemoveAlert = false
    @State private var showReportAlert = false
    @State private var showTurnOffNotifAlert = false
    @State private var showAIPopup = false
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var potSize: String = ""
    @State private var lighting: String = ""
    @State private var placement: String = ""
    
    @Namespace private var animation
    
    init(
        device: Binding<Device>,
        loading: Bool,
        updateAction: @escaping (_ field: String, _ value: Any) -> Void,
        reportIssueAction: @escaping (_ topic: String, _ message: String) -> Void
    ) {
        _device = device
        _name = State(initialValue: device.wrappedValue.name ?? "")
        _location = State(initialValue: device.wrappedValue.location ?? "")
        _potSize = State(initialValue: device.wrappedValue.potSize ?? "")
        _lighting = State(initialValue: device.wrappedValue.lighting ?? "")
        _placement = State(initialValue: device.wrappedValue.placement ?? "")
        
        self.loading = loading
        self.updateAction = updateAction
        self.reportIssueAction = reportIssueAction
    }
    
    let sizeOptions = ["6-8", "9-12", "12-16", ">16"]
    let lightingOptions = ["Partial Sun", "Full Sun", "Shade"]
    let placementOptions = ["Indoor Home", "Indoor Office", "Outdoor"]
    
    
    var body: some View {
        let color = device.status?.color ?? .gray
        VStack(spacing: 20) {
            if (device.status?.toString == "offline") {
                VStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.ultraThickMaterial)
                        .frame(width: 40, height: 5)
                        .padding(.top, 20)
                        .zIndex(1)
                    
                    Spacer()
                    
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .foregroundColor(.black)
                        .font(.system(size: 40))
                        .padding(.bottom)
                    
                    Text(device.name ?? "Probe")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 2)
                    
                    Text("This probe is disconnected.")
                        .font(.subheadline)
                    
//                    DeviceReconnectLink() // only app target sees this
                    
                    Spacer()
                }
            } else {
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack {
                                VStack(alignment: .center) {
                                    Text("\(device.location ?? "Scroll down to set a location")")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(hex: "#555"))
                                    
                                    Text(device.name ?? "Probe")
                                        .fontWeight(.medium)
                                        .font(.largeTitle)
                                }
                                .padding()
                                .padding(.vertical, 25)
                                .multilineTextAlignment(.center)
                                
                                HStack(spacing: 0) {
                                    VStack {
                                        if device.status?.description != nil {
                                            if device.status == .new {
                                                Text("Soil State")
                                                    .font(.callout)
                                                    .foregroundStyle(Color(hex: "#666"))
                                                    .padding(.bottom, 2)
                                                
                                                Text(device.status!.description)
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.gray)
                                            } else {
                                                Text("Soil Feels")
                                                    .font(.callout)
                                                    .foregroundStyle(Color(hex: "#666"))
                                                
                                                Text(device.status!.description)
                                                    .font(.largeTitle)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(color)
                                            }
                                        } else {
                                            Text("Soil State")
                                                .font(.callout)
                                                .foregroundStyle(Color(hex: "#666"))
                                                .padding(.bottom, 2)
                                            
                                            Text("Not Available")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    
                                    Divider()
                                    
                                    VStack(spacing: 0) {
                                        if let nextWater = device.nextWaterTime, !nextWater.isEmpty {
                                            if device.status == .new {
                                                VStack {
                                                    HStack(spacing:4) {
                                                        Text("Water Forcast")
                                                            .font(.callout)
                                                            .foregroundStyle(Color(hex: "#666"))
                                                        
                                                        Button {
                                                            withAnimation(.linear(duration: 0.2)) {
                                                                showAIPopup = true
                                                            }
                                                        } label: {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.gray.opacity(0.6))
                                                                    .frame(width: 12, height: 12)
                                                                
                                                                Text("?")
                                                                    .foregroundStyle(Color.white)
                                                                    .font(.caption2)
                                                                    .fontWeight(.bold)
                                                            }
                                                        }
                                                    }
                                                    .padding(.bottom, 2)
                                                    
                                                    Text("Not Available")
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(.gray)
                                                }
                                            } else if nextWater == "today" {
                                                VStack(spacing: 0) {
                                                    HStack(spacing: 4) {
                                                        Text("Water")
                                                            .font(.callout)
                                                            .foregroundStyle(Color(hex: "#666"))
                                                        
                                                        Button {
                                                            withAnimation(.linear(duration: 0.2)) {
                                                                showAIPopup = true
                                                            }
                                                        } label: {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.gray.opacity(0.6))
                                                                    .frame(width: 12, height: 12)
                                                                
                                                                Text("?")
                                                                    .foregroundStyle(Color.white)
                                                                    .font(.caption2)
                                                                    .fontWeight(.bold)
                                                            }
                                                        }
                                                    }
                                                    
                                                    Text("Today")
                                                        .font(.largeTitle)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(color)
                                                }
                                            } else {
                                                VStack(spacing: 0) {
                                                    HStack(spacing: 4) {
                                                        Text("Water In")
                                                            .font(.callout)
                                                            .foregroundStyle(Color(hex: "#666"))
                                                        
                                                        Button {
                                                            withAnimation(.linear(duration: 0.2)) {
                                                                showAIPopup = true
                                                            }
                                                        } label: {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.gray.opacity(0.6))
                                                                    .frame(width: 12, height: 12)
                                                                
                                                                Text("?")
                                                                    .foregroundStyle(Color.white)
                                                                    .font(.caption2)
                                                                    .fontWeight(.bold)
                                                            }
                                                        }
                                                    }
                                                    
                                                    Text("\(nextWater) day\(nextWater == "1" ? "" : "s")")
                                                        .fontWeight(.bold)
                                                        .font(.largeTitle)
                                                        .foregroundStyle(color)
                                                }
                                            }
                                        } else {
                                            VStack {
                                                HStack(spacing:4) {
                                                    Text("Water Forcast")
                                                        .font(.callout)
                                                        .foregroundStyle(Color(hex: "#666"))
                                                    
                                                    Button {
                                                        withAnimation(.linear(duration: 0.2)) {
                                                            showAIPopup = true
                                                        }
                                                    } label: {
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.gray.opacity(0.6))
                                                                .frame(width: 12, height: 12)
                                                            
                                                            Text("?")
                                                                .foregroundStyle(Color.white)
                                                                .font(.caption2)
                                                                .fontWeight(.bold)
                                                        }
                                                    }
                                                }
                                                .padding(.bottom, 2)
                                                
                                                Text("Not Available")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                }
                                .padding(.bottom)
                            }
                            .multilineTextAlignment(.center)
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Moisture History")
                                    .font(.callout)
                                    .foregroundStyle(Color(hex: "#666"))
                                HistoryChart(
                                    readings: device.moistureHistory,
                                    thresholds: device.thresholds!,
                                    deviceStatus: device.status
                                )
                            }
                            .padding(.bottom, 25)
                            
                            VStack(alignment: .leading) {
                                Text("Pot Size (inch)")
                                    .font(.callout)
                                    .foregroundStyle(Color(hex: "#666"))
                                
                                VStack(spacing: 12) {
                                    ForEach(sizeOptions.chunked(into: 4), id: \.self) { rowItems in
                                        HStack(spacing: 12) {
                                            ForEach(rowItems, id: \.self) { option in
                                                Button(action: {
                                                    device.potSize = option
                                                    updateAction("potSize", option)
                                                }) {
                                                    Text(option)
                                                        .font(.footnote)
                                                        .padding(.vertical, 8)
                                                        .frame(maxWidth: .infinity) // fill available space in this row
                                                        .background(device.potSize == option ? color.opacity(0.1) : Color.gray.opacity(0.05))
                                                        .foregroundColor(.black)
                                                        .cornerRadius(24)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 24)
                                                                .stroke(device.potSize == option ? color : color.opacity(0.25), lineWidth: 1.5)
                                                        )
                                                }
                                                .background(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .fill(Color.white.opacity(0.05))
                                                )
                                                .shadow(color: Color.white.opacity(0.2), radius: 1, x: -1, y: -1)
                                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 1)
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom)
                                
                                Text("Lighitng")
                                    .font(.callout)
                                    .foregroundStyle(Color(hex: "#666"))
                                
                                VStack(spacing: 12) {
                                    ForEach(lightingOptions.chunked(into: 4), id: \.self) { rowItems in
                                        HStack(spacing: 12) {
                                            ForEach(rowItems, id: \.self) { option in
                                                Button(action: {
                                                    device.lighting = option
                                                    updateAction("lighting", option)
                                                }) {
                                                    Text(option)
                                                        .font(.footnote)
                                                        .padding(.vertical, 8)
                                                        .frame(maxWidth: .infinity) // fill available space in this row
                                                        .background(device.lighting == option ? color.opacity(0.1) : Color.gray.opacity(0.05))
                                                        .foregroundColor(.black)
                                                        .cornerRadius(24)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 24)
                                                                .stroke(device.lighting == option ? color : color.opacity(0.25), lineWidth: 1.5)
                                                        )
                                                }
                                                .background(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .fill(Color.white.opacity(0.05))
                                                )
                                                .shadow(color: Color.white.opacity(0.2), radius: 1, x: -1, y: -1)
                                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 1)
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom)
                                
                                Text("Placement")
                                    .font(.callout)
                                    .foregroundStyle(Color(hex: "#666"))
                                
                                VStack(spacing: 12) {
                                    ForEach(placementOptions.chunked(into: 3), id: \.self) { rowItems in
                                        HStack(spacing: 12) {
                                            ForEach(rowItems, id: \.self) { option in
                                                Button(action: {
                                                    device.placement = option
                                                    updateAction("placement", option)
                                                }) {
                                                    Text(option)
                                                        .font(.footnote)
                                                        .padding(.vertical, 8)
                                                        .frame(maxWidth: .infinity) // fill available space in this row
                                                        .background(device.placement == option ? color.opacity(0.1) : Color.gray.opacity(0.05))
                                                        .foregroundColor(.black)
                                                        .cornerRadius(24)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 24)
                                                                .stroke(device.placement == option ? color : color.opacity(0.25), lineWidth: 1.5)
                                                        )
                                                }
                                                .background(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .fill(Color.white.opacity(0.05))
                                                )
                                                .shadow(color: Color.white.opacity(0.2), radius: 1, x: -1, y: -1)
                                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 1, y: 1)
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom)
                            }
                            
                            Spacer()
                            
                            VStack {
                                HStack {
                                    Text("Nickname & Location")
                                        .font(.callout)
                                        .foregroundStyle(Color(hex: "#666"))
                                    Spacer()
                                }
                                
                                TextField("Plant Nickname", text: $name, onCommit: {
                                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        //                                print("empty name")
                                        return
                                    }
                                    device.name = trimmed
                                    updateAction("name", trimmed)
                                    name = ""
                                })
                                .keyboardType(.default)
                                .textContentType(.nickname)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(24)
                                .autocapitalization(.none)
                                
                                TextField("Plant Location", text: $location, onCommit: {
                                    let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        // print("empty location")
                                        return
                                    }
                                    device.location = trimmed
                                    updateAction("location", trimmed)
                                    location = ""
                                })
                                .keyboardType(.default)
                                .submitLabel(.done)
                                .textContentType(.location)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(24)
                                .autocapitalization(.none)
                            }
                            .padding(.bottom, 25)
                            
                            Divider()
                            
                            HStack {
                                Spacer()
                                
                                if device.notitificationEnabled ?? false {
                                    Button("Notification is On") {
                                        showTurnOffNotifAlert = true
                                    }
                                    .foregroundStyle(.green)
                                    .font(.footnote)
                                    .alert("Toggle Probe Notification", isPresented: $showTurnOffNotifAlert) {
                                        Button("Turn Off", role: .destructive) {
                                            device.notitificationEnabled = !(device.notitificationEnabled ?? false)
                                            updateAction("notitificationEnabled", (device.notitificationEnabled ?? false))
                                            showTurnOffNotifAlert = false
                                        }
                                        Button("Cancel", role: .cancel) {
                                            showTurnOffNotifAlert = false
                                        }
                                    } message: {
                                        Text("Turning Off nitications for this probe will prevent any alerts from being sent. Data continues to be collected but you won't be notified when to water.")
                                    }
                                } else {
                                    Button("Notification is Off") {
                                        device.notitificationEnabled = !(device.notitificationEnabled ?? false)
                                        updateAction("notitificationEnabled", (device.notitificationEnabled ?? false))
                                    }
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                                }
                                
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 3, height: 3)
                                    .padding(.horizontal, 4)
                                
                                Button("Disconnect Probe") {
                                    showRemoveAlert = true
                                }
                                .foregroundStyle(.orange)
                                .font(.footnote)
                                .alert("Disconnect This Probe", isPresented: $showRemoveAlert) {
                                    Button("Disconnect", role: .destructive) {
                                        updateAction("disconnected", !(device.status?.toString == "offline"))
                                        showRemoveAlert = false
                                    }
                                    Button("Cancel", role: .cancel) {
                                        showRemoveAlert = false
                                    }
                                } message: {
                                    Text("To re-connect this probe you will have to follow the initial setup steps. This may cause loss of moisture history. ")
                                }
                                
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 3, height: 3)
                                    .padding(.horizontal, 4)
                                
                                Button("Report Issue") {
                                    showReportAlert = true
                                }
                                .foregroundStyle(.blue)
                                .font(.footnote)
                                .confirmationDialog("Report An Issue", isPresented: $showReportAlert, titleVisibility: .visible) {
                                    Button("Physical Issue") {
                                        reportIssueAction("Physical Issue", "")
                                    }
                                    Button("Setup Mode Failing") {
                                        reportIssueAction("Setup Mode Failing", "")
                                    }
                                    Button("Updating Plant Info") {
                                        reportIssueAction("Updating Plant Info", "")
                                    }
                                    Button("Login/Logout") {
                                        reportIssueAction("Login/Logout", "")
                                    }
                                    Button("Abnormal Readings") {
                                        reportIssueAction("Abnormal Readings", "")
                                    }
                                    Button("Wi-Fi") {
                                        reportIssueAction("Wi-Fi", "")
                                    }
                                    Button("Notification") {
                                        reportIssueAction("Notification", "")
                                    }
                                    Button("Other") {
                                        reportIssueAction("Other", "")
                                    }
                                    Button("Cancel", role: .cancel) {}
                                } message: {
                                    Text("Select a topic that best describes your issue.")
                                }
                                
                                Spacer()
                                
                            }
                            .padding(.vertical)
                            
                            HStack {
                                Spacer()
                                
                                VStack(alignment: .center) {
                                    Text("Probe Identifier")
                                    Text(encodedId)
                                }
                                .font(.caption2)
                                .foregroundStyle(.gray.opacity(0.45))
                                Spacer()
                                VStack(alignment: .center) {
                                    Text("Harware Version")
                                    Text(device.hardwareVersion ?? "1.0.0")
                                }
                                .font(.caption2)
                                .foregroundStyle(.gray.opacity(0.45))
                                Spacer()
                                VStack(alignment: .center) {
                                    Text("Firmware Version")
                                    Text(device.firmwareVersion ?? "1.0.0")
                                }
                                .font(.caption2)
                                .foregroundStyle(.gray.opacity(0.45))
                                Spacer()
                            }
                            .padding(.bottom)
                        }
                        .padding()
                    }
                    
                    // AI Popup overlay
                    if showAIPopup {
                        // Full-screen dark translucent background
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.linear(duration: 0.1)) {
                                    showAIPopup = false
                                }
                            }
                        
                        // Centered popup
                        VStack(spacing: 16) {
                            Text("Watering Forecast With AI")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("The watering forecast is generated using advanced AI models that analyze various factors to provide the best possible estimate. However, please keep in mind that it is still a prediction and cannot guarantee 100% accuracy under all conditions. Use it as a helpful guide, but always consider your plant’s specific needs.")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Close") {
                                withAnimation(.linear(duration: 0.1)) {
                                    showAIPopup = false
                                }
                            }
                            .underline()
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(50)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(15)
                        .transition(.opacity)
                    }
                    
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.ultraThickMaterial)
                        .frame(width: 40, height: 5)
                        .padding(.top, 20)
                        .zIndex(1)
                } //ZStack
            }
        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 52, style: .continuous))
        .padding(5)
    }
}

struct HistoryChartThreshold: Identifiable, Codable {
    let id: Int  // stored once
    let value: Int
    let label: String
}


struct HistoryChart: View {
    let readings: [MoistureReading]
    let thresholds: [HistoryChartThreshold]
    let deviceStatus: DeviceStatus?
    
    // live tracker
    let duration: Double = 6
    let pulseCount = 2
    
    let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    var body: some View {
        let color = deviceStatus?.color ?? .gray
        let oldestReadingTime = readings.map { $0.timestamp }.min() ?? Date()
        let lastReadingTime = readings.map { $0.timestamp }.max() ?? Date()
        let extendedMaxDate = Calendar.current.date(byAdding: .day, value: 1, to: lastReadingTime) ?? lastReadingTime
        
        if readings.isEmpty || deviceStatus == .new {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Not enough readings.")
                        .font(.subheadline)
                    Spacer()
                }
                Spacer()
            }
            .frame(height: 215)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(25)
        } else {
            Chart(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("Moisture", reading.moisture)
                )
                .interpolationMethod(.monotone)
                .symbol(Circle())
                .foregroundStyle(color.opacity(0.8))
                
                AreaMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("Moisture", reading.moisture)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.3), .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                PointMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("Moisture", reading.moisture)
                )
                .symbol {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .background(Circle().fill(Color.white))
                        .frame(width: 7, height: 7)
                }
                .annotation(position: .overlay, alignment: .center) {
                    if deviceStatus?.toString != nil && deviceStatus?.toString != "offline" && readings.count > 1 && reading.id == readings.first?.id {
                        TimelineView(.animation) { timeline in
                            let now = timeline.date.timeIntervalSinceReferenceDate
                            
                            ZStack {
                                ForEach(0..<pulseCount, id: \.self) { i in
                                    let phase = Double(i) / Double(pulseCount)
                                    let progress = ((now / duration) - phase).truncatingRemainder(dividingBy: 1)
                                    let clampedProgress = progress < 0 ? progress + 1 : progress
                                    
                                    Circle()
                                        .stroke(color.opacity(0.8 * (1 - clampedProgress)), lineWidth: 2)
                                        .frame(width: 7, height: 7)
                                        .scaleEffect(1 + 3 * clampedProgress)
                                }
                            }
                            .frame(width: 30, height: 30)
                        }
                        .allowsHitTesting(false)
                        
                    }
                }
                
            }
            .frame(height: 215)
            .chartXScale(domain: oldestReadingTime...extendedMaxDate)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(hourFormatter.string(from: dateValue))
                        }
                    }
                }
            }
            .chartYScale(domain: 0...thresholds.last!.value) // set max chart limit
            .chartYAxis { // Dynamically set the chart threasholds
                AxisMarks(values: thresholds.map { $0.value }) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Int.self),
                           let threshold = thresholds.first(where: { $0.value == val }) {
                            Text(threshold.label)
                                .offset(x: 4)
                        }
                    }
                }
            }
        }
    }
}


let sampleDevices: [Device] = (1...7).map { i in
    let name = ["Leaf Fig", "Monstera", "Snake Plant", "Peace Lily", "ZZ", "Bird of Paradise", "Dracaena", "Corn Plant", "Ficus", "Heartleaf"][Int(i) - 1]
    let location = ["Kitchen", "Living Room", "Balcony", "Bedroom", "Bathroom", "Office", "Basement"].randomElement()!
    let potSize = [">16", "12–16", "9–12", "6-8"].randomElement()!
    let lighting = ["Full Sun", "Partial Sun", "Shade"].randomElement()!
    let placement = ["Indoor Home", "Indoor Office", "Outdoor"].randomElement()!
    
    // Determine moisture range and status
    let moistureRange: ClosedRange<Int>
    let status: DeviceStatus

    let roll = Int.random(in: 1...100)
    if roll <= 10 {
        moistureRange = 100_000...250_000
        status = .dry
    } else if roll <= 20 {
        moistureRange = 250_001...350_000
        status = .okay
    } else if roll <= 35 {
        moistureRange = 250_001...350_000
        status = .ideal
    } else if roll <= 85 {
        moistureRange = 350_001...500_000
        status = .wet
    } else {
        moistureRange = 500_001...600_000
        status = .new
    }

    let moistureHistory = (0..<15).map { j in
        MoistureReading(
            timestamp: Calendar.current.date(byAdding: .day, value: -j, to: Date())!,
            moisture: Int.random(in: moistureRange)
        )
    }
    
    let defaultThresholds: [HistoryChartThreshold] = [
        HistoryChartThreshold(id: 0, value: 0, label: "Dry"),
        HistoryChartThreshold(id: 1, value: 150000, label: "Low"),
        HistoryChartThreshold(id: 2, value: 300000, label: "Ideal"),
        HistoryChartThreshold(id: 3, value: 450000, label: "High"),
        HistoryChartThreshold(id: 4, value: 500000, label: "Wet")
    ]
    
    return Device(
        deviceId: "B4:3A:45:34:BD:\(String(format: "%02X", i))",
        name: name,
        location: location,
        status: status,
        potSize: potSize,
        lighting: lighting,
        placement: placement,
        hardwareVersion: "1.0.\(i)",
        firmwareVersion: "2.1.\(i)",
        notitificationEnabled: Bool.random(),
        moistureHistory: moistureHistory,
        thresholds: defaultThresholds,
        nextWaterTime: "3",
    )
}

