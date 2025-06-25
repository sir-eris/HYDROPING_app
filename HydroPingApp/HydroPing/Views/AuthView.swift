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
//                    .shadow(color: .white.opacity(0.2), radius: 1, x: -1, y: -1)
//                    .shadow(color: .gray.opacity(0.5), radius: 2, x: 1, y: 1)
                
                Image("logo-text")
                    .resizable()
                    .scaledToFit()
//                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300)
                    .frame(height: 100)
//                    .clipped()
                
                Spacer()
                
                AuthButtonsUI()
                    .padding(.horizontal)
                
                Link(destination: URL(string: "https://hydroping.com")!) {
                    Text("Visit HydroPing.com")
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundStyle(.gray)
