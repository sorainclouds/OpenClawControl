import SwiftUI

struct VisionMainView: View {
    @State private var isConnected: Bool = false
    @State private var selectedTab: VisionTab = .status
    
    enum VisionTab: String, CaseIterable {
        case status = "状态"
        case chat = "聊天"
        case sessions = "会话"
    }
    
    var body: some View {
        NavigationSplitView {
            List(VisionTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: iconFor(tab))
                    .tag(tab)
            }
            .navigationTitle("OpenClaw")
        } detail: {
            detailView
                .navigationTitle(selectedTab.rawValue)
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .status:
            VisionStatusView(isConnected: isConnected)
        case .chat:
            VisionChatView(isConnected: isConnected)
        case .sessions:
            VisionSessionsView()
        }
    }
    
    private func iconFor(_ tab: VisionTab) -> String {
        switch tab {
        case .status: return "gauge.with.dots.needle.bottom.50percent"
        case .chat: return "bubble.left.and.bubble.right"
        case .sessions: return "list.bullet.rectangle"
        }
    }
}

struct VisionStatusView: View {
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(isConnected ? .green : .red)
            
            Text(isConnected ? "已连接" : "未连接")
                .font(.title2)
            
            if isConnected {
                Text("系统运行正常")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct VisionChatView: View {
    let isConnected: Bool
    @State private var message: String = ""
    
    var body: some View {
        VStack {
            if isConnected {
                ScrollView {
                    Text("消息列表")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    TextField("发送消息", text: $message)
                    Button("发送") {}
                }
                .padding()
            } else {
                Text("未连接到服务器")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct VisionSessionsView: View {
    var body: some View {
        List {
            Text("会话列表")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VisionMainView()
}
