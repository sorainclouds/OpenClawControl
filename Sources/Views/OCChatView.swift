import SwiftUI

// MARK: - Chat View

struct OCChatView: View {
    @Bindable var viewModel: OCViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 连接状态栏
                if !viewModel.isConnected {
                    ConnectionBanner(viewModel: viewModel)
                }
                
                // 消息列表
                if viewModel.isConnected {
                    MessageListView(
                        messages: viewModel.currentSessionKey.flatMap { viewModel.messages[$0] } ?? [],
                        sessionKey: viewModel.currentSessionKey
                    )
                } else {
                    NotConnectedView()
                }
                
                // 输入框
                if viewModel.isConnected {
                    ChatInputView(
                        text: $viewModel.chatInput,
                        onSend: {
                            Task {
                                await viewModel.sendMessage(viewModel.chatInput)
                            }
                        }
                    )
                    .focused($isInputFocused)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if viewModel.isConnected {
                        Button {
                            Task {
                                await viewModel.refreshStatus()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .task {
                if viewModel.isConnected {
                    await viewModel.refreshStatus()
                }
            }
        }
    }
    
    private var navigationTitle: String {
        if !viewModel.isConnected {
            return "OpenClaw"
        }
        if let sessionKey = viewModel.currentSessionKey,
           let session = viewModel.sessions.first(where: { $0.key == sessionKey }) {
            return session.kind.capitalized
        }
        return "聊天"
    }
}

// MARK: - Connection Banner

struct ConnectionBanner: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("未连接到服务器")
            Spacer()
            Button("连接") {
                Task {
                    await viewModel.connect()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.red.opacity(0.1))
    }
}

// MARK: - Not Connected View

struct NotConnectedView: View {
    var body: some View {
        ContentUnavailableView(
            "未连接",
            systemImage: "wifi.slash",
            description: Text("请在设置中配置服务器连接")
        )
    }
}

// MARK: - Message List

struct MessageListView: View {
    let messages: [OCMessage]
    let sessionKey: String?
    
    var body: some View {
        if messages.isEmpty {
            ContentUnavailableView(
                "暂无消息",
                systemImage: "bubble.left",
                description: Text("开始发送消息吧")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: OCMessage
    
    var body: some View {
        HStack(alignment: .top) {
            // 头像
            Circle()
                .fill(message.senderId == "user" ? .blue : .orange)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(message.senderId.prefix(1)).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(message.content)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Chat Input

struct ChatInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("输入消息...", text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit(onSend)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
            }
            .disabled(text.isEmpty)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    OCChatView(viewModel: OCViewModel())
}
