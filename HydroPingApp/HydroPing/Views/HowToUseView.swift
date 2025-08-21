//
//  HowToUseView.swift
//  Probe
//
//  Created by Ramtin Mir on 7/13/25.
//

import SwiftUI
import StoreKit


struct HowToUseView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    private let sections: [SectionData] = [
        .init(id: "unbox", title: "Unbox Your Probe", body: "Carefully remove the moisture probe from its packaging. You should see the probe itself and a quick start guide. No cables are included, as the device is powered by a built-in, non-rechargeable battery."),

        .init(id: "setup", title: "Setting Up A Probe", body: "The probe does not require charging. To begin setup, open the app and follow the steps in the 'Add a Device' section. Make sure Wi-Fi is enabled on your phone."),

        .init(id: "wifi", title: "Connecting To Wi-Fi", body: "Shake the probe firmly to activate setup mode. Then go to your phone’s Wi-Fi settings and connect to the network named **HydroPing-Probe-WiFi**. This confirms the probe is ready to be linked."),

            .init(id: "wifiError", title: "On Failure To Connect To Wi-Fi", body: "If you don’t see **HydroPing-Probe-WiFi**, shake the probe again while holding it vertically. Wait a few seconds and recheck your Wi-Fi list. If it still doesn’t appear, move to a less congested area. As a last resort, wait 15 minutes for the probe to automatically reset, then shake again to re-enter setup mode and retry the connection."),


        .init(id: "soil", title: "Inserting Into Soil", body: "Insert the probe vertically into the soil until the metal (aluminum) section is fully submerged, up to the plastic cap. Position it near the plant’s roots and away from large stems or rocks for best results."),

        .init(id: "verify", title: "Verify Connection", body: "After setup, the app will display your plant with live data. If it doesn’t appear, ensure you're connected to **HydroPing-Probe-WiFi** and retry the app’s connection steps."),

        .init(id: "monitor", title: "Monitor Moisture", body: "The app continuously receives soil moisture data from your probe. You'll get alerts when it's time to water and can view moisture history to better understand your plant's needs."),
        
            .init(id: "waterAmount", title: "Water Amount Calculation", body: "HydroPing doesn’t measure the exact amount of water poured—it monitors how your soil responds to watering. After watering, you’ll see how the moisture level changes, helping you understand how much is just right. Every plant, pot, and soil mix is a little different, so over time, you’ll learn what amount works best. Think of it as feedback in real-time: water, check the reading, and adjust as needed next time. It’s less about measuring and more about listening to what your plant’s soil is telling you."),

        .init(id: "reposition", title: "Reposition Of A Probe", body: "To move the probe to another plant within the same home, simply insert it into the new pot and update the plant name or attributes in the app. No need to shake or reset. If relocating to another home with a different Wi-Fi, shake the probe to re-enter setup mode and connect it to the new network."),

        .init(id: "adding", title: "Adding More Probes", body: "To set up additional probes, shake each new one until **HydroPing-Probe-WiFi** appears in your Wi-Fi settings. Connect to it and follow the app’s 'Add a Device' steps. Each probe will be listed separately in your dashboard."),

    ]

    @Namespace private var scrollID
    @State private var scrollTarget: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Landing Image
                    Image("landing")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(40)
                        .padding()

                    // Text Navigation
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                                Button(action: {
                                    withAnimation {
                                        proxy.scrollTo(section.id, anchor: .top)
                                    }
                                }) {
                                    Text("\(index + 1). \(section.title)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color(hex: "#008000"))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Section Content
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(index + 1). \(section.title)")
                                .font(.title2.bold())
                            Text(section.body)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.bottom)
                        }
                        .padding(.horizontal)
                        .id(section.id)
                    }

                    Spacer(minLength: 40)
                    
                    HStack {
                        Spacer()
                        VStack(alignment: .center) {
                            Button("Rate This App") {
                                if let scene = UIApplication.shared.connectedScenes
                                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                    if #available(iOS 18.0, *) {
                                        AppStore.requestReview(in: scene)
                                    } else {
                                        SKStoreReviewController.requestReview(in: scene)
                                    }
                                }
                            }
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                            .underline()
                            .fontWeight(.semibold)
                            .padding(.bottom)
                            
                            Link(destination: URL(string: "https://hydroping.com")!) {
                                Text("Visit HydroPing.com")
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .foregroundStyle(.gray)
                                    .underline()
                            }
                            Text("HydroPing © 2025, All Rights Reserved.")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("How To Use")
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
        .overlay(alignment: .top) {
            GradientMaterialOverlay()
                .frame(height: 100)
                .ignoresSafeArea(edges: .top)
        }
    }
}

struct SectionData: Identifiable {
    let id: String
    let title: String
    let body: String
}


#Preview {
    HowToUseView()
}
