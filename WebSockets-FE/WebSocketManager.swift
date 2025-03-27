import Foundation
import Combine

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    
    
    @Published var isConnected = false
    @Published var messages: [WebSocketMessage] = []
    
    // Configure with your WebSocket server URL
    private let serverURL = URL(string: "ws://localhost:3000")!
    
    struct WebSocketMessage: Identifiable {
        let id = UUID()
        let text: String
        let isFromUser: Bool
        let timestamp = Date()
    }
    
    func connect() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
        
        // Setup ping to keep connection alive
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        pingTimer?.invalidate()
        pingTimer = nil
        self.messages = []
    }
    
    func send(message: String) {
        guard isConnected else { return }
        
        // Create a JSON message matching the server's expected format
        let messageDict: [String: Any] = [
            "sender": "iOSUser", // You might want to make this configurable
            "content": message
        ]
        
        // Convert dictionary to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            
            webSocketTask?.send(wsMessage) { [weak self] error in
                if let error = error {
                    print("Error sending message: \(error)")
                    return
                }
                
                // Add the message to the UI immediately when sent
                DispatchQueue.main.async {
                    self?.messages.append(WebSocketMessage(text: message, isFromUser: true))
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    // Try to parse the incoming JSON message
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = json["content"] as? String,
                       let sender = json["sender"] as? String {
                        
                        // Only add the message if it's not from the current user
                        if sender != "iOSUser" {
                            DispatchQueue.main.async {
                                self?.messages.append(WebSocketMessage(text: content, isFromUser: false))
                            }
                        }
                        else if sender == "iOSUser" {
                            DispatchQueue.main.async {
                                self?.messages.append(WebSocketMessage(text: content, isFromUser: true))
                            }
                        }
                    } else {
                        // Fallback for non-JSON messages
                        DispatchQueue.main.async {
                            self?.messages.append(WebSocketMessage(text: text, isFromUser: false))
                        }
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.messages.append(WebSocketMessage(text: text, isFromUser: false))
                        }
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self?.receiveMessage()
                
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.disconnect()
            }
        }
    }
    
    private func ping() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("Error sending ping: \(error)")
                self.disconnect()
            }
        }
    }
} 
