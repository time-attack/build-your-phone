import Foundation
import Network

#if DEBUG

@MainActor
public final class StateServer {
    private var listener: NWListener?
    private var readHandlers: [String: () -> String] = [:]
    private var writeHandlers: [String: (String) -> Bool] = [:]
    public private(set) var port: UInt16 = 0
    private var hasConnected = false

    public init() {}

    public func registerRead(_ key: String, handler: @escaping @MainActor () -> String) {
        readHandlers[key] = handler
    }

    public func registerWrite(_ key: String, handler: @escaping @MainActor (String) -> Bool) {
        writeHandlers[key] = handler
    }

    public func start(port: UInt16 = 9999) {
        do {
            let params = NWParameters.tcp
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)

            listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        if let p = self?.listener?.port?.rawValue {
                            self?.port = p
                            print("[DebugBridge] StateServer listening on http://localhost:\(p)")
                        }
                    case .failed(let error):
                        print("[DebugBridge] StateServer failed: \(error)")
                        self?.listener?.cancel()
                    default:
                        break
                    }
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleConnection(connection)
                }
            }

            listener?.start(queue: .main)
        } catch {
            print("[DebugBridge] Failed to start StateServer: \(error)")
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            Task { @MainActor in
                guard let self = self, let data = data else {
                    connection.cancel()
                    return
                }
                self.handleRequest(data, on: connection)
            }
        }
    }

    private func handleRequest(_ data: Data, on connection: NWConnection) {
        guard let raw = String(data: data, encoding: .utf8) else {
            sendResponse(connection, status: 400, body: "Bad request")
            return
        }

        // Signal first connection
        if !hasConnected {
            hasConnected = true
            DebugBridgeNotifier.connected()
        }
        DebugBridgeNotifier.action("request")

        // Parse HTTP request line
        let lines = raw.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection, status: 400, body: "Bad request")
            return
        }

        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else {
            sendResponse(connection, status: 400, body: "Bad request")
            return
        }

        let method = String(parts[0])
        let path = String(parts[1])

        // Route: GET /state → list all keys
        if method == "GET" && path == "/state" {
            let keys = Array(readHandlers.keys).sorted()
            let json = "[\(keys.map { "\"\($0)\"" }.joined(separator: ","))]"
            sendResponse(connection, status: 200, body: json, contentType: "application/json")
            return
        }

        // Route: GET /state/{key} → read handler
        if method == "GET", path.hasPrefix("/state/") {
            let key = String(path.dropFirst("/state/".count))
            if let handler = readHandlers[key] {
                let value = handler()
                sendResponse(connection, status: 200, body: value, contentType: "application/json")
                DebugBridgeNotifier.action("read \(key)")
            } else {
                sendResponse(connection, status: 404, body: "{\"error\":\"key not found: \(key)\"}")
            }
            return
        }

        // Route: POST /state/{key} → write handler (body is the value)
        if method == "POST", path.hasPrefix("/state/") {
            let key = String(path.dropFirst("/state/".count))
            // Extract body after \r\n\r\n
            let bodyValue: String
            if let bodyRange = raw.range(of: "\r\n\r\n") {
                bodyValue = String(raw[bodyRange.upperBound...])
            } else {
                bodyValue = ""
            }

            if let handler = writeHandlers[key] {
                let ok = handler(bodyValue)
                if ok {
                    DebugBridgeNotifier.action("write \(key)")
                    DebugBridgeNotifier.stateMutation()
                    sendResponse(connection, status: 200, body: "{\"ok\":true}")
                } else {
                    sendResponse(connection, status: 400, body: "{\"ok\":false,\"error\":\"write rejected\"}")
                }
            } else {
                sendResponse(connection, status: 404, body: "{\"error\":\"key not found: \(key)\"}")
            }
            return
        }

        // Route: GET /health → health check
        if method == "GET" && path == "/health" {
            sendResponse(connection, status: 200, body: "{\"status\":\"ok\"}")
            return
        }

        sendResponse(connection, status: 404, body: "{\"error\":\"not found\"}")
    }

    private func sendResponse(_ connection: NWConnection, status: Int, body: String, contentType: String = "application/json") {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        default: statusText = "Error"
        }

        let response = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: response.data(using: .utf8), contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

#endif
