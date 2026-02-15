import SwiftUI

// MARK: - Main Tab View

struct OCMainTabView: View {
    @State private var viewModel = OCViewModel()
    @State private var selectedTab: OCAppTab = .chat
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 聊天
            OCChatView(viewModel: viewModel)
                .tabItem {
                    Label("聊天", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(OCAppTab.chat)
            
            // 数据看板
            OCDashboardView(viewModel: viewModel)
                .tabItem {
                    Label("看板", systemImage: "chart.bar")
                }
                .tag(OCAppTab.dashboard)
            
            // 会话列表
            OCSessionsView(viewModel: viewModel)
                .tabItem {
                    Label("会话", systemImage: "list.bullet.rectangle")
                }
                .tag(OCAppTab.sessions)
            
            // 设置
           OCSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(OCAppTab.settings)
        }
        .tint(.blue)
    }
}

enum OCAppTab: Hashable {
    case chat
    case dashboard
    case sessions
    case settings
}

#Preview {
    OCMainTabView()
}
