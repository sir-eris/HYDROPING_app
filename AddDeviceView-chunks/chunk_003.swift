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
    
