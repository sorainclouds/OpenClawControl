import SwiftUI

// MARK: - Sessions View

struct OCSessionsView: View {
    @Bindable var viewModel: OCViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isConnected {
                    if viewModel.sessions.isEmpty {
                        ContentUnavailableView(
                            "暂无会话",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("会话将在这里显示")
                        )
                    } else {
                        List(viewModel.sessions) { session in
                            SessionRow(
                                session: session,
                                isSelected: session.key == viewModel.currentSessionKey
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.currentSessionKey = session.key
                                Task {
                                    await viewModel.refreshMessages(for: session.key)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    NotConnectedView()
                }
            }
            .navigationTitle("会话列表")
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

struct SessionRow: View {
    let session: OCSession
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: session.kind == "direct" ? "person.circle.fill" : "person.3.circle.fill")
                .font(.title2)
                .foregroundStyle(isSelected ? .blue : .secondary)
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(session.key.components(separatedBy: ":").last ?? session.key)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(session.model, systemImage: "brain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(session.tokens)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 时间
            Text(session.age)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OCSessionsView(viewModel: OCViewModel())
}
