import Foundation

// MARK: - OpenClaw API Service

actor OCAPIService {
    private var config: OCServerConfig = .default
    
    func updateConfig(_ newConfig: OCServerConfig) {
        config = newConfig
    }
    
    var baseURL: String {
        switch config.connectionType {
        case .tailscale, .local:
            return config.baseURL
        case .vpn, .cloudflare, .publicNetwork:
            return config.baseURL
        }
    }
    
    var authHeaders: [String: String] {
        var headers = ["Content-Type": "application/json"]
        if !config.authToken.isEmpty {
            headers["Authorization"] = "Bearer \(config.authToken)"
        }
        return headers
    }
    
    // MARK: - API Methods
    
    func fetchStatus() async throws -> OCStatus {
        let url = "\(baseURL)/api/status"
        return try await request(url: url, method: "GET")
    }
    
    func fetchSessions() async throws -> [OCSession] {
        let url = "\(baseURL)/api/sessions"
        return try await request(url: url, method: "GET")
    }
    
    func fetchMessages(sessionKey: String, limit: Int = 50) async throws -> OCMessages {
        let url = "\(baseURL)/api/sessions/\(sessionKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sessionKey)/messages?limit=\(limit)"
        return try await request(url: url, method: "GET")
    }
    
    func sendMessage(_ content: String, sessionKey: String? = nil, channel: String? = nil, target: String? = nil) async throws {
        let url = "\(baseURL)/api/message"
        
        var body: [String: Any] = ["message": content]
        if let sessionKey = sessionKey {
            body["sessionKey"] = sessionKey
        }
        if let channel = channel {
            body["channel"] = channel
        }
        if let target = target {
            body["target"] = target
        }
        
        let data = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = data
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OCAPIError.sendFailed
        }
    }
    
    func sendChannelMessage(channel: String, message: String, target: String? = nil) async throws {
        let url = "\(baseURL)/api/message"
        
        var body: [String: Any] = [
            "message": message,
            "channel": channel
        ]
        if let target = target {
            body["target"] = target
        }
        
        let data = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = data
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OCAPIError.sendFailed
        }
    }
    
    func testConnection() async -> Bool {
        do {
            let _ = try await fetchStatus()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private
    
    private func request<T: Decodable>(url: String, method: String) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw OCAPIError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OCAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw OCAPIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Errors

enum OCAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case sendFailed
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code): return "HTTP 错误: \(code)"
        case .sendFailed: return "发送消息失败"
        case .notConnected: return "未连接到服务器"
        }
    }
}
