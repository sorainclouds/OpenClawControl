import Foundation

// MARK: - OpenClaw WebSocket Client

class OCWebSocketClient: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    private var isConnected = false
    private var pendingRequests: [String: (Result<Any, Error>) -> Void] = [:]
    private var onEvent: ((String, [String: Any]) -> Void)?
    
    private var gatewayURL: String = ""
    private var token: String = ""
    
    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }
    
    func configure(url: String, token: String) {
        self.gatewayURL = url
        self.token = token
    }
    
    func connect() async throws {
        guard let url = URL(string: gatewayURL) else {
            throw OCClientError.invalidURL
        }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Wait for connection
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Send connect request
        var connectParams: [String: Any] = [
            "minProtocol": 3,
            "maxProtocol": 3,
            "client": [
                "id": "openclaw-ios",
                "version": "1.0.0",
                "platform": "ios",
                "mode": "webchat"
            ],
            "role": "operator",
            "scopes": ["operator.admin"]
        ]
        
        if !token.isEmpty {
            connectParams["auth"] = ["token": token]
        }
        
        let response: [String: Any]? = try await request("connect", connectParams)
        
        if response != nil {
            isConnected = true
            startReceiving()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }
    
    func setEventHandler(_ handler: @escaping (String, [String: Any]) -> Void) {
        self.onEvent = handler
    }
    
    // MARK: - Request/Response
    
    func request(_ method: String, _ params: [String: Any] = [:]) async throws -> [String: Any]? {
        let id = UUID().uuidString
        
        let request: [String: Any] = [
            "type": "req",
            "id": id,
            "method": method,
            "params": params
        ]
        
        let data = try JSONSerialization.data(withJSONObject: request)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw OCClientError.encodingError
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = { result in
                switch result {
                case .success(let value):
                    if let dict = value as? [String: Any] {
                        continuation.resume(returning: dict)
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    self.pendingRequests.removeValue(forKey: id)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.startReceiving()
            case .failure:
                self?.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            processJSON(json)
        case .data(let data):
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                processJSON(json)
            }
        @unknown default:
            break
        }
    }
    
    private func processJSON(_ json: [String: Any]) {
        let type = json["type"] as? String ?? ""
        
        if type == "res" {
            let id = json["id"] as? String
            if let id = id, let callback = pendingRequests.removeValue(forKey: id) {
                if let error = json["error"] as? [String: Any] {
                    callback(.failure(OCClientError.serverError(error["message"] as? String ?? "Unknown")))
                } else {
                    callback(.success(json["payload"] ?? json))
                }
            }
        } else if type == "event" {
            let event = json["event"] as? String ?? ""
            let payload = json["payload"] as? [String: Any] ?? [:]
            onEvent?(event, payload)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension OCWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
}

// MARK: - Errors

enum OCClientError: LocalizedError {
    case invalidURL
    case encodingError
    case notConnected
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .encodingError: return "编码错误"
        case .notConnected: return "未连接到服务器"
        case .serverError(let msg): return msg
        }
    }
}
