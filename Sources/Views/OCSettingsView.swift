import SwiftUI

// MARK: - Settings View

struct OCSettingsView: View {
    @Bindable var viewModel: OCViewModel
    @State private var showConnectionConfig = false
    
    var body: some View {
        NavigationStack {
            List {
                // 连接配置
                Section {
                    Button {
                        showConnectionConfig = true
                    } label: {
                        HStack {
                            Label("服务器配置", systemImage: "server.rack")
                            Spacer()
                            Text(viewModel.isConnected ? "已连接" : "未连接")
                                .foregroundStyle(viewModel.isConnected ? .green : .secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    if viewModel.isConnected {
                        HStack {
                            Text("服务器地址")
                            Spacer()
                            Text(viewModel.serverConfig.baseURL)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("连接")
                }
                
                // 连接管理
                Section {
                    if viewModel.isConnected {
                        Button(role: .destructive) {
                            viewModel.disconnect()
                        } label: {
                            Label("断开连接", systemImage: "wifi.slash")
                        }
                    } else {
                        Button {
                            Task {
                                await viewModel.connect()
                            }
                        } label: {
                            if viewModel.isConnecting {
                                Label("连接中...", systemImage: "arrow.triangle.2.circlepath")
                            } else {
                                Label("连接服务器", systemImage: "wifi")
                            }
                        }
                        .disabled(viewModel.isConnecting)
                    }
                }
                
                // 数据
                Section {
                    Button {
                        Task {
                            await viewModel.refreshStatus()
                        }
                    } label: {
                        Label("刷新数据", systemImage: "arrow.clockwise")
                    }
                }
                
                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://docs.openclaw.ai")!) {
                        Label("帮助文档", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showConnectionConfig) {
                ConnectionConfigView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Connection Config View

struct ConnectionConfigView: View {
    @Bindable var viewModel: OCViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("连接方式", selection: $viewModel.serverConfig.connectionType) {
                        ForEach(OCConnectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                } header: {
                    Text("连接类型")
                } footer: {
                    Text(viewModel.serverConfig.connectionType.description)
                }
                
                Section {
                    TextField("服务器地址", text: $viewModel.serverConfig.baseURL)
                        .autocorrectionDisabled()
                    
                    SecureField("认证 Token", text: $viewModel.serverConfig.authToken)
                    
                    if viewModel.serverConfig.connectionType == .tailscale {
                        TextField("Tailscale IP (可选)", text: Binding(
                            get: { viewModel.serverConfig.tailscaleIP ?? "" },
                            set: { viewModel.serverConfig.tailscaleIP = $0.isEmpty ? nil : $0 }
                        ))
                        .autocorrectionDisabled()
                    }
                } header: {
                    Text("服务器信息")
                } footer: {
                    connectionHelpText
                }
                
                Section {
                    Button("测试连接") {
                        Task {
                            await viewModel.testConnection()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    if let result = viewModel.connectionTestResult {
                        Text(result)
                            .foregroundStyle(result.contains("成功") ? .green : .red)
                    }
                }
            }
            .navigationTitle("服务器配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.saveConfig()
                        Task {
                            await viewModel.connect()
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    @ViewBuilder
    private var connectionHelpText: some View {
        switch viewModel.serverConfig.connectionType {
        case .local:
            Text("例如: http://192.168.1.100:18789 或 http://127.0.0.1:18789")
        case .tailscale:
            Text("填写 Tailscale 分配的 IP 地址，例如: http://100.x.x.x:18789")
        case .vpn:
            Text("填写 VPN 或内网穿透服务提供的地址")
        case .cloudflare:
            Text("填写 Cloudflare Tunnel 映射的域名")
        case .publicNetwork:
            Text("填写公网地址，建议使用 HTTPS")
        }
    }
}

#Preview {
    OCSettingsView(viewModel: OCViewModel())
}
