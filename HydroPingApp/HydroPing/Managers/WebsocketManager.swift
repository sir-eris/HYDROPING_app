//
//  WebsocketHelper.swift
//  Probe
//
//  Created by Ramtin Mir on 7/3/25.
//

import Foundation

class WebSocketManager: NSObject, ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!

    private let url = URL(string: "ws://192.168.4.1/ws")! // Your ESP32 WebSocket URL

    @Published var isConnected: Bool = false
    @Published var currentMessage: String = ""
    @Published var setupSteps: [String] = ["credentials received", "Connecting To Wi-Fi", "Connected To Wi-Fi", "Registering Probe", "Registered"]
    @Published var currentStepIndex: Int = 0
    @Published var error: String?
    
    private var messageQueue: [String] = []
    private var isDisplayingMessage = false

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }

    func connect() {
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }

    func send(_ message: String) {
        guard let task = webSocketTask else { return }
        let message = URLSessionWebSocketTask.Message.string(message)
        task.send(message) { error in
            if let _ = error {
//                print("❌ WebSocket send error:", error)
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure( _):
//                print("❌ WebSocket receive error:", error)
                DispatchQueue.main.async { self.isConnected = false }

            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.enqueueMessage(text)
//                        print("✅ Received: \(text)")
                    }
                default:
                    break
                }
                self.listen()
            }
        }
    }
    
    func enqueueMessage(_ text: String) {
        messageQueue.append(text)
        updateStepProgress(for: text)
        displayNextMessageIfNeeded()
    }
    
    private func updateStepProgress(for message: String) {
        guard currentStepIndex < setupSteps.count else { return }
        
        let expected = setupSteps[currentStepIndex]
                
        // Handle known error messages
        if message.localizedCaseInsensitiveContains("Wi-Fi Connection Failed") {
            handleError("Wi-Fi connection failed. Please check your credentials.")
            return
        } else if message.localizedCaseInsensitiveContains("Probe Registration Failed") {
            handleError("Probe registration failed.")
            return
        } else if message.localizedCaseInsensitiveContains("error") {
            handleError("An unknown error occurred during setup.")
            return
        }
        
        if message.localizedCaseInsensitiveContains(expected) {
            currentStepIndex += 1
        }
    }
        
    private func displayNextMessageIfNeeded() {
        guard !isDisplayingMessage, !messageQueue.isEmpty else { return }
        
        isDisplayingMessage = true
        currentMessage = messageQueue.removeFirst()
        
        // Display each message for 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isDisplayingMessage = false
            self.displayNextMessageIfNeeded()
        }
    }
    
    private func handleError(_ errorMessage: String) {
        error = errorMessage
        messageQueue.removeAll() // Optional: clear queue on failure
        currentStepIndex = 0     // Optional: reset progress
    }

    func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// MARK: - WebSocket Delegate
extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
//        print("✅ WebSocket connected")
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
//        print("❌ WebSocket disconnected")
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}
