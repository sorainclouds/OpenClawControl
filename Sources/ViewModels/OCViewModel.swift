import Foundation
import Combine

// MARK: - Main ViewModel

@MainActor
@Observable
class OCViewModel {
    // MARK: - Properties
    
    let apiService = OCAPIService()
    
    var serverConfig: OCServerConfig = .default
    var isConnected: Bool = false
    var isConnecting: Bool = false
    var status: OCStatus?
    var sessions: [OCSession] = []
    var messages: [String: [OCMessage]] = [:]
    var currentSessionKey: String?
    var currentTask: String = "空闲中"
    var modelUsage: ModelUsage = .zero
    var errorMessage: String?
    
    // Chat
    var chatInput: String = ""
    var selectedChannel: String = "qqbot"
    
    // Settings
    var showSettings: Bool = false
    var connectionTestResult: String?
    
    // MARK: - Model Usage
    
    struct ModelUsage {
        var inputTokens: Int = 0
        var outputTokens: Int = 0
        var totalTokens: Int = 0
        var sessionCount: Int = 0
    }
    
    // MARK: - Initialization
    
    init() {
        loadConfig()
    }
    
    // MARK: - Connection
    
    func connect() async {
        isConnecting = true
        errorMessage = nil
        
        await apiService.updateConfig(serverConfig)
        let connected = await apiService.testConnection()
        
        isConnected = connected
        isConnecting = false
        
        if connected {
            await refreshStatus()
            saveConfig()
        } else {
            errorMessage = "无法连接到服务器，请检查配置"
        }
    }
    
    func disconnect() {
        isConnected = false
        sessions = []
        messages = [:]
        status = nil
    }
    
    // MARK: - Data Fetching
    
    func refreshStatus() async {
        guard isConnected else { return }
        
        do {
            status = try await apiService.fetchStatus()
            sessions = try await apiService.fetchSessions()
            calculateUsage()
        } catch {
            errorMessage = "获取状态失败: \(error.localizedDescription)"
        }
    }
    
    func refreshMessages(for sessionKey: String) async {
        guard isConnected else { return }
        
        do {
            let msgs = try await apiService.fetchMessages(sessionKey: sessionKey)
            messages[sessionKey] = msgs.messages.reversed()
        } catch {
            errorMessage = "获取消息失败: \(error.localizedDescription)"
        }
    }
    
    func sendMessage(_ content: String) async {
        guard isConnected, !content.isEmpty else { return }
        
        do {
            if let sessionKey = currentSessionKey {
                try await apiService.sendMessage(content, sessionKey: sessionKey)
                await refreshMessages(for: sessionKey)
            } else {
                try await apiService.sendChannelMessage(channel: selectedChannel, message: content)
            }
            chatInput = ""
            await refreshStatus()
        } catch {
            errorMessage = "发送失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private
    
    private func calculateUsage() {
        var total = 0
        for session in sessions {
            let tokenStr = session.tokens.replacingOccurrences(of: "k", with: "000")
                .replacingOccurrences(of: "/200k", "")
                .trimmingCharacters(in: .whitespaces)
            if let tokens = Int(tokenStr.components(separatedBy: "/").first ?? "0") {
                total += tokens
            }
        }
        
        modelUsage = ModelUsage(
            totalTokens: total,
            sessionCount: sessions.count
        )
    }
    
    // MARK: - Persistence
    
    private var configURL: URL {
        let groupID = "group.com.openclaw.control"
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            return container.appendingPathComponent("config.json")
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("openclaw_config.json")
    }
    
    func saveConfig() {
        do {
            let data = try JSONEncoder().encode(serverConfig)
            try data.write(to: configURL)
        } catch {
            print("保存配置失败: \(error)")
        }
    }
    
    func loadConfig() {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: configURL)
            serverConfig = try JSONDecoder().decode(OCServerConfig.self, from: data)
        } catch {
            print("加载配置失败: \(error)")
        }
    }
    
    // MARK: - Connection Helper
    
    func testConnection() async {
        connectionTestResult = nil
        await apiService.updateConfig(serverConfig)
        let connected = await apiService.testConnection()
        connectionTestResult = connected ? "✅ 连接成功" : "❌ 连接失败"
    }
}
