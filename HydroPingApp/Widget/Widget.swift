//
//  widget.swift
//  widget
//
//  Created by Ramtin Mir on 7/2/25.
//

import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
    private let keychainService = "token"
    private let appGroup = "group.com.erisverne.hydroping"
    private let accessGroup = "M673G6VLXY.com.erisverne.hydroping.shared"
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), devices: [], isLoggedIn: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        loadDevices { devices in
            var maxDevices: Int = 4
            if context.family == .systemLarge || context.family == .systemExtraLarge {
                maxDevices = 10
            }
                        
            let entry = SimpleEntry(date: Date(), devices: Array(devices.prefix(maxDevices)), isLoggedIn: true)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        loadDevices { devices in
            let sharedDefaults = UserDefaults(suiteName: appGroup)
            let isLoggedIn = sharedDefaults?.string(forKey: "userId") != nil
            
            var maxDevices: Int = 4
            if context.family == .systemLarge || context.family == .systemExtraLarge {
                maxDevices = 10
            }

            let entry = SimpleEntry(date: Date(), devices: Array(devices.prefix(maxDevices)), isLoggedIn: isLoggedIn)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(2 * 60 * 60))) // 2hrs
            completion(timeline)
        }
    }

    struct FetchDevicesResponse: Decodable {
        let newToken: String?
        let devices: [Device]
    }
    private func loadDevices(completion: @escaping ([Device]) -> ()) {
        // 1. Read email and token
        let sharedDefaults = UserDefaults(suiteName: appGroup)
        guard let email = sharedDefaults?.string(forKey: "userEmail") else {
            print("Token not found1")
            completion([])
            return
        }

        guard let tokenData = KeychainManager.standard.read(service: keychainService, account: email, accessGroup: accessGroup),
              let token = String(data: tokenData, encoding: .utf8) else {
            print("Token not found2")
            completion([])
            return
        }

        // 2. Build API request
        guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/getUserProbes") else {
            print("Token not found3")
            completion([])
            return
        }
                
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let cleanedToken = token.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        request.setValue("Bearer \(cleanedToken)", forHTTPHeaderField: "Authorization")
        
        // 3. Perform API call        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error:", error.localizedDescription)
                completion([])
                return
            }
            
//            if let data = data, let body = String(data: data, encoding: .utf8) {
//                print("Response body:", body)
//            }
//            if let httpResponse = response as? HTTPURLResponse {
//                print("HTTP status code:", httpResponse.statusCode)
//                if httpResponse.statusCode != 200 {
//                    print("Server responded with error")
//                    completion([])
//                    return
//                }
//            }
            
            guard let data = data else {
                print("No data received")
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let results = try decoder.decode(FetchDevicesResponse.self, from: data)
                
//                if let token = results.newToken {
//                    session.renewToken(token: token)
//                }
                
                completion(results.devices)
            } catch {
                print("Decoding error:", error.localizedDescription)
                completion([])
            }
        }
        task.resume()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let devices: [Device]
    let isLoggedIn: Bool
}

struct widgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.isLoggedIn {
            Text("Sign in to help your plants.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
        } else if entry.devices.isEmpty {
            Text("No plants found.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
        } else {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(entry.devices.filter { $0.status?.toString != "offline" }.enumerated()), id: \.element.id) { index, device in
                        let color = device.status?.color ?? .gray
                        
                        HStack {
                            if family == .systemSmall {
                                Circle()
                                    .fill(color)
                                    .frame(width: 10, height: 10)
                            }
                            
                            Text(device.name?.isEmpty == false ? device.name! : "Plant")
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Spacer()
                            
                            if family != .systemSmall {
                                Text(device.location ?? "–")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 105, alignment: .leading)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                MoistureBar(moisture: device.firstMoistureValue, maxMoisture: 600_000, statusColor: color)
                            }
                        }
                        
//                        count excluding offline devices
                        if index < Array(entry.devices.filter { $0.status?.toString != "offline" }.enumerated()).count - 1 {
                            Divider()
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
        }
    }
}

struct HydropingWidget: Widget {
    let kind: String = "HydropingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                widgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                widgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Plant Status")
        .description("Shows the current status of your plant's soil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}


#Preview(as: .systemMedium) {
    HydropingWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        devices: Array(sampleDevices.prefix(4)),
        isLoggedIn: true
    )
}


