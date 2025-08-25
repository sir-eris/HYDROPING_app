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
