import Foundation
import SwiftUI
import Combine

// MARK: - Main ViewModel

@Observable
class OCViewModel {
    // MARK: - Properties
    
    var client: OCWebSocketClient = OCWebSocketClient()
    
    var serverConfig: OCServerConfig = .default
    var isConnected: Bool = false
    var isConnecting: Bool = false
    var status: GatewaySnapshot?
    var sessions: [OCSession] = []
    var messages: [String: [OCMessage]] = [:]
    var currentSessionKey: String?
    var currentTask: String = "空闲中"
    var modelUsage: ModelUsage = ModelUsage()
    var errorMessage: String?
    
    // Chat
    var chatInput: String = ""
    var chatMessages: [OCMessage] = []
    var selectedChannel: String = "qqbot"
    
    // Settings
    var showSettings: Bool = false
    var connectionTestResult: String?
    
    // MARK: - Model Usage
    
    struct ModelUsage {
        static var zero: ModelUsage { ModelUsage() }
        
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
    
    @MainActor
    func connect() async {
        isConnecting = true
        errorMessage = nil
        
        do {
            // Convert http to ws
            var wsURL = serverConfig.baseURL
                .replacingOccurrences(of: "http://", with: "ws://")
                .replacingOccurrences(of: "https://", with: "wss://")
            
            if !wsURL.hasPrefix("ws://") && !wsURL.hasPrefix("wss://") {
                wsURL = "ws://" + wsURL
            }
            
            client.configure(url: wsURL, token: serverConfig.authToken)
            client.setEventHandler { [weak self] event, payload in
                Task { @MainActor in
                    self?.handleEvent(event, payload: payload)
                }
            }
            
            try await client.connect()
            isConnected = true
            await refreshStatus()
            saveConfig()
        } catch {
            errorMessage = "连接失败: \(error.localizedDescription)"
            isConnected = false
        }
        
        isConnecting = false
    }
    
    func disconnect() {
        client.disconnect()
        isConnected = false
        sessions = []
        messages = [:]
        status = nil
        chatMessages = []
    }
    
    // MARK: - Event Handling
    
    @MainActor
    private func handleEvent(_ event: String, payload: [String: Any]) {
        switch event {
        case "chat":
            handleChatEvent(payload)
        case "presence":
            // Update presence
            break
        case "agent":
            // Agent event
            break
        default:
            break
        }
    }
    
    @MainActor
    private func handleChatEvent(_ payload: [String: Any]) {
        guard let sessionKey = payload["sessionKey"] as? String,
              sessionKey == currentSessionKey else {
            return
        }
        
        let state = payload["state"] as? String
        
        if state == "delta" || state == "final" {
            Task {
                await refreshMessages(for: sessionKey)
            }
        }
    }
    
    // MARK: - Data Fetching
    
    @MainActor
    func refreshStatus() async {
        guard isConnected else { return }
        
        do {
            // Fetch sessions
            if let response = try await client.request("sessions.list", ["activeMinutes": 120]) {
                parseSessionsResponse(response)
            }
            
            // Fetch health
            if let response = try await client.request("gateway.health", [:]) {
                // Parse health status
            }
            
            calculateUsage()
        } catch {
            errorMessage = "获取状态失败: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func refreshMessages(for sessionKey: String) async {
        guard isConnected else { return }
        
        do {
            if let response = try await client.request("chat.history", [
                "sessionKey": sessionKey,
                "limit": 100
            ]) {
                parseMessagesResponse(response, for: sessionKey)
            }
        } catch {
            errorMessage = "获取消息失败: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func sendMessage(_ content: String) async {
        guard isConnected, !content.isEmpty else { return }
        
        do {
            let params: [String: Any] = [
                "sessionKey": currentSessionKey ?? "main",
                "message": content,
                "deliver": false
            ]
            
            _ = try await client.request("chat.send", params)
            chatInput = ""
            await refreshStatus()
        } catch {
            errorMessage = "发送失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private
    
    private func parseSessionsResponse(_ response: [String: Any]) {
        // Parse sessions from response
        if let sessionsData = response["sessions"] as? [[String: Any]] {
            sessions = sessionsData.map { dict in
                OCSession(
                    key: dict["key"] as? String ?? "",
                    kind: dict["kind"] as? String ?? "direct",
                    age: dict["age"] as? String ?? "",
                    model: dict["model"] as? String ?? "",
                    tokens: dict["tokens"] as? String ?? ""
                )
            }
        }
    }
    
    private func parseMessagesResponse(_ response: [String: Any], for sessionKey: String) {
        if let messagesData = response["messages"] as? [[String: Any]] {
            chatMessages = messagesData.map { dict in
                OCMessage(
                    id: dict["id"] as? String ?? UUID().uuidString,
                    senderId: dict["senderId"] as? String ?? dict["role"] as? String ?? "unknown",
                    content: extractContent(from: dict),
                    timestamp: dict["timestamp"] as? String ?? "",
                    source: dict["source"] as? String
                )
            }
        }
    }
    
    private func extractContent(from dict: [String: Any]) -> String {
        if let content = dict["content"] as? String {
            return content
        }
        if let contentArray = dict["content"] as? [[String: Any]] {
            return contentArray.compactMap { item -> String? in
                if let type = item["type"] as? String, type == "text",
                   let text = item["text"] as? String {
                    return text
                }
                return nil
            }.joined()
        }
        return ""
    }
    
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
    
    @MainActor
    func testConnection() async {
        connectionTestResult = nil
        
        var wsURL = serverConfig.baseURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        
        if !wsURL.hasPrefix("ws://") && !wsURL.hasPrefix("wss://") {
            wsURL = "ws://" + wsURL
        }
        
        let testClient = OCWebSocketClient()
        testClient.configure(url: wsURL, token: serverConfig.authToken)
        
        do {
            try await testClient.connect()
            connectionTestResult = "连接成功"
            testClient.disconnect()
        } catch {
            connectionTestResult = "连接失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Additional Models

struct GatewaySnapshot: Codable {
    let presence: [PresenceEntry]?
    let sessionDefaults: SessionDefaults?
    let health: HealthInfo?
}

struct PresenceEntry: Codable {
    let sessionKey: String
    let channel: String
    let connectedAt: Int
}

struct SessionDefaults: Codable {
    let mainSessionKey: String?
    let mainKey: String?
    let defaultAgentId: String?
}

struct HealthInfo: Codable {
    let gateway: String?
    let agents: String?
    let memory: String?
}
