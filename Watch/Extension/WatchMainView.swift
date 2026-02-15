import SwiftUI

struct WatchMainView: View {
    @State private var isConnected: Bool = false
    @State private var status: String = "未连接"
    @State private var sessions: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                // 连接状态
                Section {
                    HStack {
                        Circle()
                            .fill(isConnected ? .green : .red)
                            .frame(width: 10, height: 10)
                        Text(status)
                    }
                }
                
                // 快速信息
                Section("概览") {
                    Label("活跃会话: \(sessions)", systemImage: "bubble.left.and.bubble.right")
                }
                
                // 操作
                Section {
                    Button(isConnected ? "刷新" : "连接") {
                        // 简化版：仅显示状态
                    }
                }
            }
            .navigationTitle("OpenClaw")
        }
    }
}

#Preview {
    WatchMainView()
}
