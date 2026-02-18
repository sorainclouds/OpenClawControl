import SwiftUI

// MARK: - Dashboard View

struct OCDashboardView: View {
    @Bindable var viewModel: OCViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isConnected {
                    VStack(spacing: 16) {
                        // 连接状态卡片
                        StatusCard(viewModel: viewModel)
                        
                        // 令牌使用量
                        TokenUsageCard(viewModel: viewModel)
                        
                        // 活跃会话
                        ActiveSessionsCard(viewModel: viewModel)
                        
                        // 通道状态
                        ChannelsCard(viewModel: viewModel)
                        
                        // 当前任务
                        CurrentTaskCard(viewModel: viewModel)
                    }
                    .padding()
                } else {
                    NotConnectedView()
                }
            }
            .navigationTitle("数据看板")
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
}

// MARK: - Status Card

struct StatusCard: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("系统状态", systemImage: "server.rack")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(viewModel.isConnected ? .green : .red)
                    .frame(width: 10, height: 10)
                
                Text(viewModel.isConnected ? "已连接" : "未连接")
                    .font(.subheadline)
                
                Spacer()
                
                if let status = viewModel.status {
                    Text(status.gateway.local)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Token Usage Card

struct TokenUsageCard: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Token 使用量", systemImage: "brain.head.profile")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "会话数",
                    value: "\(viewModel.modelUsage.sessionCount)",
                    icon: "person.2"
                )
                
                StatItem(
                    title: "Token",
                    value: formatTokens(viewModel.modelUsage.totalTokens),
                    icon: "textformat.123"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1000 {
            return String(format: "%.1fK", Double(tokens) / 1000)
        }
        return "\(tokens)"
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Sessions Card

struct ActiveSessionsCard: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("活跃会话", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)
            
            if viewModel.sessions.isEmpty {
                Text("暂无活跃会话")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.sessions.prefix(5)) { session in
                    HStack {
                        Image(systemName: session.kind == "direct" ? "person" : "person.3")
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(session.model)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(session.tokens) • \(session.age)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Channels Card

struct ChannelsCard: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("通道", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
            
            if let channels = viewModel.status?.channels {
                ForEach(channels, id: \.channel) { channel in
                    HStack {
                        Circle()
                            .fill(channel.enabled ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(channel.channel)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(channel.state)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("无法获取通道信息")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Current Task Card

struct CurrentTaskCard: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("当前任务", systemImage: "gearshape.2")
                .font(.headline)
            
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text(viewModel.currentTask)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    OCDashboardView(viewModel: OCViewModel())
}
