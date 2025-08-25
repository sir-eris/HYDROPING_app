//
//  SignInView.swift
//  Probe
//
//  Created by Ramtin Mir on 6/30/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseCore


struct AuthButtonsUI: View {
    @EnvironmentObject var session: SessionManager

    @State private var isLoading = false
    @State private var showAccountDeletedAlert = false

    var body: some View {
        VStack(spacing: 30) {
            if isLoading == true {
                ProgressView()
            } else {
                ZStack {
                    VStack(spacing: 12) {
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                isLoading = true
                                
                                switch result {
                                case .success(let authResults):
                                    if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                        Task {
                                            await handleAppleSignIn(credential: appleIDCredential)
                                            
                                            DispatchQueue.main.async {
                                                isLoading = false
                                            }
                                        }
                                    } else {
                                        isLoading = false
                                    }
                                case .failure(_):
                                    // print("Authorization failed: \(error.localizedDescription)")
                                    isLoading = false
                                    //                                break
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(24)
                        
                        
                        Button(action: {
                            DispatchQueue.main.async {
                                isLoading = true
                            }
                            signInWithGoogle {
                                DispatchQueue.main.async {
                                    isLoading = false
                                }
                            }
                        }) {
                            HStack {
                                Image("google_logo")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .aspectRatio(contentMode: .fit)
                                Text("Sign in with Google")
                                    .fontWeight(.medium)
                                    .font(.system(size: 19))
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .cornerRadius(24)
                        .foregroundColor(.black)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(style: StrokeStyle(lineWidth: 0.5))
                        )
                        //                    .disabled(isLoading)
                    }
                }
            }
        }
        .padding()
        .alert("Account Deleted", isPresented: $showAccountDeletedAlert) {
            Button("Continue") {
                // start new account flow
                showAccountDeletedAlert = false
            }
            Button("Cancel", role: .cancel) { showAccountDeletedAlert = false}
        } message: {
            Text("Your account was deleted. Tap continue, and retry sign-in for a new account to be created.")
        }
    }
    
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            //            print("Failed to get identity token")
            return
        }
        
        let userId = credential.user
        let email = credential.email ?? ""
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let body: [String: Any] = [
            "identityToken": identityToken,
            "userId": userId,
            "email": email,
            "fullName": fullName
        ]
        
        guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/appleSignIn") else {
            //            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            //            print("JSON serialization error:", error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                //                print("Network error:", error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 410 {
//                    print("Account deleted (410 Gone)")
                    DispatchQueue.main.async { showAccountDeletedAlert = true }
                    return
                }
            }
//            if let data = data, let bodyString = String(data: data, encoding: .utf8) {
//                print("Response body: \(bodyString)")
//            }
            
            guard let data = data else {
                //                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    //                    print("Response JSON:", json)
                    
                    if let token = json["token"] as? String,
                       let user = json["userId"] as? String,
                       let email = json["email"] as? String{
                        Task {
                            await session.signIn(token: token, userId: user, email: email)
                        }
                    } else if let errorMsg = json["error"] as? String {
                        //                        print("Backend error:", errorMsg)
                        return
                    }
                }
            } catch {
                //                print("JSON parse error:", error)
            }
        }
        task.resume()
    }

    func signInWithGoogle(completion: @escaping () -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
//            print("Missing clientID")
            completion()
            return
        }

        _ = GIDConfiguration(clientID: clientID)
        
        guard let presentingVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first else {
//            print("❌ No rootViewController found")
            completion()
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
            if let error = error {
//                print("Google Sign-In error:", error.localizedDescription)
                completion()
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
//                print("❌ Missing auth tokens")
                completion()
                return
            }
            
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
//                    print("Firebase sign-in failed:", error.localizedDescription)
                    completion()
                    return
                } else {
//                    print("✅ Signed in as:", authResult?.user.email ?? "Unknown")
                    guard let user = authResult?.user else {
//                        print("no user info available on authResult")
                        completion()
                        return
                    }
                    
                    user.getIDToken { idToken, error in
                        if let error = error {
//                            print("Error fetching ID token:", error)
                            completion()
                            return
                        }
                        if let idToken = idToken {
                            let body: [String: Any] = [
                                "idToken": idToken,
                                "email": user.email ?? "",
                                "isSignUp": authResult?.additionalUserInfo?.isNewUser ?? false,
//                                "userId": user.uid,
//                                "fullName": user.displayName ?? "",
//                                "phone": user.phoneNumber ?? "",
//                                "photoUrl": user.photoURL?.absoluteString ?? ""
                            ]
                            
                            
                            guard let url = URL(string: "https://q15ur4emu9.execute-api.us-east-2.amazonaws.com/default/googleSignIn") else {
//                                print("Invalid URL")
                                completion()
                                return
                            }
                            
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            
                            do {
                                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                            } catch {
//                                print("JSON serialization error:", error)
                                completion()
                                return
                            }
                            
                            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                if let error = error {
//                                    print("Network error:", error)
                                    completion()
                                    return
                                }
                                
                                if let httpResponse = response as? HTTPURLResponse {
//                                    print(httpResponse.statusCode)
                                    if httpResponse.statusCode == 410 {
//                                        print("Account deleted (410 Gone)")
                                        DispatchQueue.main.async { showAccountDeletedAlert = true }
                                        completion()
                                        return
                                    }
                                }
                                
                                guard let data = data else {
//                                    print("No data received")
                                    completion()
                                    return
                                }
                                
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                                        print("Response JSON:", json)
                                        
                                        if let token = json["token"] as? String,
                                           let user = json["userId"] as? String,
                                           let email = json["email"] as? String{
                                            Task {
                                                await session.signIn(token: token, userId: user, email: email)
                                            }
                                        } else if let errorMsg = json["error"] as? String {
//                                            print("Backend error:", errorMsg)
                                        }
                                        
                                        completion()
                                    }
                                } catch {
//                                    print("JSON parse error:", error)
                                    completion()
                                    return
                                }
                            }
                            task.resume()
                        }
                    }
                }
            }
        }
        
        isLoading = false
    }
}

#Preview {
    AuthButtonsUI().environmentObject(SessionManager())
}
