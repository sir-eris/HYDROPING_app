//
//  ProfileView.swift
//  HydroPing
//
//  Created by Ramtin Mir on 8/22/25.
//

import SwiftUI
import WidgetKit

struct ProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var session: SessionManager
    
    let deviceNotification: Bool = false
    
    @State private var showRemoveAccountAlert = false
    @State private var showToggleNotificationAlert = false
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ZStack {
                    EmailAvatar(email: session.email ?? "someone@someemail.com", width: 400, height: 300)
                        .blur(radius: 50)
                        .ignoresSafeArea(edges: .top)
                        .padding(.bottom)
                    
                    Text("\(session.email ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.black)          // text color
                        .padding(.horizontal, 20)         // horizontal padding
                        .padding(.vertical, 6)            // vertical padding
                        .background(Color.white)          // pill background
                        .cornerRadius(20)                 // make it rounded
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1) // optional
                        .padding(.bottom)
                }
                .frame(width: 400, height: 300)
                
                Link(destination: URL(string: "https://hydroping.com/collections/all")!) {
                    VStack {
                        HStack {
                            Text("Buy more probes")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(0)
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal)
                
                Link(destination: URL(string: "https://hydroping.com/pages/apple-app-widget-extension-installation-walkthrough")!) {
                    VStack {
                        HStack {
                            Text("Add Widget")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(0)
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Remove Account") {
                    showToggleNotificationAlert = true
                }
                .foregroundStyle(.red)
                .font(.footnote)
                .alert("Remove Your Entire Account", isPresented: $showToggleNotificationAlert) {
                    Button("Remove", role: .destructive) {
                        Task { await removeAccount() }
                        showToggleNotificationAlert = false
                    }
                    Button("Cancel", role: .cancel) {
                        showToggleNotificationAlert = false
                    }
                } message: {
                    Text("Are you sure you want to permanently remove your entire account and all associated data? This action cannot be undone.")
                }
                
                Circle()
                    .fill(Color.gray)
                    .frame(width: 3, height: 3)
                    .padding(.horizontal, 4)
                
                Button("Logout") {
                    session.signOut()
                }
                .foregroundStyle(.orange)
                .font(.footnote)
                
                Spacer()
                
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            //            Back
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
    
    func removeAccount() async {
        guard let _ = session.userId else {
            // print("Invalid userId")
            session.signOut()
            return
        }
        guard let jwtToken = session.token else {
            session.signOut()
//            print( "Invalid token")
            return
        }
        guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/removeAccount") else {
            // print("Invalid URL")
            return
        }
        
        let body: [String: Any] = [:]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
//            would be weird!
            if let httpResponse = response as? HTTPURLResponse {
//                print(httpResponse.statusCode)
                if httpResponse.statusCode == 410 {
//                    print("Account deleted (410 Gone)")
                    DispatchQueue.main.async { session.signOut() }
                    return
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
//                print("Server error or invalid response")
//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Status: \(httpResponse.statusCode)")
//                }
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("Response: \(jsonString)")
//                }
                return
            }
            
            await MainActor.run {
                session.signOut()
                WidgetCenter.shared.reloadAllTimelines()
            }
            
        } catch {
            //            print("Failed to update device info: \(error.localizedDescription)")
        }
    }
}


#Preview {
    ProfileView().environmentObject(SessionManager())
}
