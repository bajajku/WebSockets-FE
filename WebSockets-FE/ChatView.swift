import SwiftUI

struct ChatView: View {
    @StateObject private var wsManager = WebSocketManager()
    @State private var messageText = ""
    @State private var showingConnectionSheet = false
    
    var body: some View {
        VStack {
            // Connection status indicator
            HStack {
                Circle()
                    .fill(wsManager.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(wsManager.isConnected ? "Connected" : "Disconnected")
                
                Spacer()
                
                Button(action: {
                    if wsManager.isConnected {
                        wsManager.disconnect()
                    } else {
                        wsManager.connect()
                    }
                }) {
                    Text(wsManager.isConnected ? "Disconnect" : "Connect")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Messages list
            ScrollView {
                LazyVStack {
                    ForEach(wsManager.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message input
            HStack {
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!wsManager.isConnected)
                
                Button(action: {
                    guard !messageText.isEmpty else { return }
                    wsManager.send(message: messageText)
                    messageText = ""
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(!wsManager.isConnected || messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("WebSocket Chat")
    }
}

struct MessageBubble: View {
    let message: WebSocketManager.WebSocketMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.text)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding(.vertical, 5)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
} 
