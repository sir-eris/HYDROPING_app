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

    var body: some View {
        VStack(spacing: 30) {
            if isLoading == true {
                ProgressView()
            } else {
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
                                isLoading = false
                                break
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
        .padding()
    }
    
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
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
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    if let token = json["token"] as? String,
                       let user = json["userId"] as? String,
                       let email = json["email"] as? String{
                        Task {
                            await session.signIn(token: token, userId: user, email: email)
                        }
                    } else if let errorMsg = json["error"] as? String {
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
            completion()
            return
        }

        _ = GIDConfiguration(clientID: clientID)
        
        guard let presentingVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first else {
            completion()
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
            if let error = error {
                completion()
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
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
                    completion()
                    return
                } else {
                    guard let user = authResult?.user else {
                        completion()
                        return
                    }
                    
                    user.getIDToken { idToken, error in
                        if let error = error {
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
                                completion()
                                return
                            }
                            
                            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                if let error = error {
                                    completion()
                                    return
                                }
                                
                                guard let data = data else {
                                    completion()
                                    return
                                }
                                
                                do {
                                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                        
                                        if let token = json["token"] as? String,
                                           let user = json["userId"] as? String,
                                           let email = json["email"] as? String{
                                            Task {
                                                await session.signIn(token: token, userId: user, email: email)
                                            }
                                        } else if let errorMsg = json["error"] as? String {
//                                          print("Backend error:", errorMsg)
                                        }
                                        
                                        completion()
                                    }
                                } catch {
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
