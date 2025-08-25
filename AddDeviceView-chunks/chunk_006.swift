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
