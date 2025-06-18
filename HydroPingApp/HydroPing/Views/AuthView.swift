//
//  AuthView.swift
//  Probe
//
//  Created by Ramtin Mir on 6/30/25.
//

import SwiftUI


struct AuthView: View {
    @EnvironmentObject var session: SessionManager
    @State private var isSignUp = false

    var body: some View {
        ZStack{
            FloatingBackgroundCircles()
            
            VStack {
//                Text("HydroPing")
//                    .font(.system(size: 48, weight: .heavy))
//                    .overlay(
//                        Text("HydroPing")
//                            .font(.system(size: 48, weight: .heavy))
//                            .foregroundStyle(Color(hex: "#010821"))
//                            .blendMode(.screen)
//                    )
