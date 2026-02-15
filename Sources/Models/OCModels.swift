import Foundation

// MARK: - OpenClaw API Models

struct OCSession: Codable, Identifiable {
    let key: String
    let kind: String
    let age: String
    let model: String
    let tokens: String
    
    var id: String { key }
}

struct OCMessage: Codable, Identifiable {
    let id: String
    let senderId: String
    let content: String
    let timestamp: String
    let source: String?
    
    var role: String {
        if senderId == "user" || senderId == "operator" {
            return "user"
        }
        return "assistant"
    }
}

struct OCStatus: Codable {
    let gateway: GatewayInfo
    let memory: MemoryInfo?
    let sessions: [OCSession]?
    let channels: [ChannelInfo]?
    
    struct GatewayInfo: Codable {
        let local: String
        let reachable: Bool
        let authToken: String
    }
    
    struct MemoryInfo: Codable {
        let enabled: Bool
    }
    
    struct ChannelInfo: Codable {
        let channel: String
        let enabled: Bool
        let state: String
    }
}

struct OCMessages: Codable {
    let messages: [OCMessage]
}

struct OCSendMessage: Codable {
    let message: String
    let channel: String?
    let target: String?
}

// MARK: - Connection Configuration

enum OCConnectionType: String, Codable, CaseIterable {
    case local = "本地网络"
    case tailscale = "Tailscale"
    case vpn = "VPN/内网穿透"
    case cloudflare = "Cloudflare Tunnel"
    case publicNetwork = "公网"
    
    var description: String {
        switch self {
        case .local: return "同一网络下访问 (ws://localhost:18789)"
        case .tailscale: return "通过 Tailscale VPN 访问"
        case .vpn: return "通过 VPN 或内网穿透服务访问"
        case .cloudflare: return "通过 Cloudflare Tunnel 访问"
        case .publicNetwork: return "通过公网域名/IP 访问"
        }
    }
}

struct OCServerConfig: Codable {
    var connectionType: OCConnectionType
    var baseURL: String          // 例如: http://192.168.1.x:18789 或 wss://your-domain.com
    var authToken: String        // Gateway 认证 token
    var tailscaleIP: String?     // Tailscale IP (可选)
    var customHeaders: [String: String]?
    
    static var `default`: OCServerConfig {
        OCServerConfig(
            connectionType: .local,
            baseURL: "ws://127.0.0.1:18789",
            authToken: "",
            tailscaleIP: nil,
            customHeaders: nil
        )
    }
}
