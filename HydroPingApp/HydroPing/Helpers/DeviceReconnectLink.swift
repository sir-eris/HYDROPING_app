//
//  DeviceReconnectLink.swift
//  HydroPing
//
//  Created by Ramtin Mir on 9/3/25.
//

import SwiftUI

struct DeviceReconnectLink: View {
    var body: some View {
        NavigationLink(destination: AddDeviceView()) {
            Text("Reconnect")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
        }
    }
}


#Preview {
    DeviceReconnectLink()
}
