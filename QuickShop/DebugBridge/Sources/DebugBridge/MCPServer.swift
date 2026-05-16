import Foundation
import Network
import UIKit

#if DEBUG

// MARK: - JSON-RPC Types

struct JSONRPCRequest: Codable {
    let jsonrpc: String
    let id: AnyCodableID?
    let method: String
    let params: [String: AnyCodable]?
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let id: AnyCodableID?
    let result: AnyCodable?
    let error: JSONRPCError?

    init(id: AnyCodableID?, result: AnyCodable) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = nil
    }

    init(id: AnyCodableID?, error: JSONRPCError) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = nil
        self.error = error
    }
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
    let data: AnyCodable?

    init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

// MARK: - AnyCodable

enum AnyCodableID: Codable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            throw DecodingError.typeMismatch(AnyCodableID.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        }
    }
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let b = try? container.decode(Bool.self) {
            value = b
        } else if let i = try? container.decode(Int.self) {
            value = i
        } else if let d = try? container.decode(Double.self) {
            value = d
        } else if let s = try? container.decode(String.self) {
            value = s
        } else if let arr = try? container.decode([AnyCodable].self) {
            value = arr.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let b as Bool:
            try container.encode(b)
        case let i as Int:
            try container.encode(i)
        case let d as Double:
            try container.encode(d)
        case let s as String:
            try container.encode(s)
        case let arr as [Any]:
            try container.encode(arr.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}

// MARK: - MCP Tool Definition

public struct MCPToolDefinition {
    let name: String
    let description: String
    let inputSchema: [String: Any]
    let handler: @MainActor @Sendable ([String: Any]) async -> Any

    public init(
        name: String,
        description: String,
        inputSchema: [String: Any],
        handler: @escaping @MainActor @Sendable ([String: Any]) async -> Any
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.handler = handler
    }
}

// MARK: - MCP Server with Bonjour Discovery

@MainActor
public final class MCPServer: @unchecked Sendable {
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var tools: [String: MCPToolDefinition] = [:]
    public private(set) var port: UInt16 = 0

    public var onConnect: (() -> Void)?
    public var onDisconnect: (() -> Void)?

    public init() {}

    public func registerTool(_ tool: MCPToolDefinition) {
        tools[tool.name] = tool
    }

    public func start() {
        do {
            let params = NWParameters.tcp
            params.requiredLocalEndpoint = nil // bind to all interfaces (WiFi + USB)

            let ws = NWProtocolWebSocket.Options()
            params.defaultProtocolStack.applicationProtocols.insert(ws, at: 0)

            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: 9876)!)

            // Advertise via Bonjour so Claude Code can discover us
            listener?.service = NWListener.Service(
                name: "istack-debug",
                type: "_istack._tcp"
            )

            listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        if let port = self?.listener?.port?.rawValue {
                            self?.port = port
                            print("[DebugBridge] MCP server listening on ws://0.0.0.0:\(port)")
                            print("[DebugBridge] Bonjour: advertising _istack._tcp as 'istack-debug'")
                        }
                    case .failed(let error):
                        print("[DebugBridge] Server failed: \(error)")
                        self?.listener?.cancel()
                    default:
                        break
                    }
                }
            }

            listener?.serviceRegistrationUpdateHandler = { change in
                switch change {
                case .add(let endpoint):
                    print("[DebugBridge] Bonjour registered: \(endpoint)")
                case .remove(let endpoint):
                    print("[DebugBridge] Bonjour removed: \(endpoint)")
                @unknown default:
                    break
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleConnection(connection)
                }
            }

            listener?.start(queue: .main)
        } catch {
            print("[DebugBridge] Failed to start server: \(error)")
        }
    }

    public func stop() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
    }

    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)
        print("[DebugBridge] Client connecting...")

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    print("[DebugBridge] Client connected!")
                    self?.onConnect?()
                case .failed, .cancelled:
                    print("[DebugBridge] Client disconnected")
                    self?.connections.removeAll { $0 === connection }
                    if self?.connections.isEmpty == true {
                        self?.onDisconnect?()
                    }
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
        receiveMessage(on: connection)
    }

    private func receiveMessage(on connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, _, error in
            guard let self = self else { return }

            if let error = error {
                print("[DebugBridge] Receive error: \(error)")
                return
            }

            if let data = content,
               let wsMetadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata,
               wsMetadata.opcode == .text {
                Task { @MainActor in
                    await self.handleMessage(data, on: connection)
                    self.receiveMessage(on: connection)
                }
            } else {
                Task { @MainActor in
                    self.receiveMessage(on: connection)
                }
            }
        }
    }

    private func handleMessage(_ data: Data, on connection: NWConnection) async {
        guard let request = try? JSONDecoder().decode(JSONRPCRequest.self, from: data) else {
            let errorResponse = JSONRPCResponse(
                id: nil,
                error: JSONRPCError(code: -32700, message: "Parse error")
            )
            sendResponse(errorResponse, on: connection)
            return
        }

        let response: JSONRPCResponse

        switch request.method {
        case "initialize":
            response = JSONRPCResponse(id: request.id, result: AnyCodable([
                "protocolVersion": "2024-11-05",
                "capabilities": ["tools": [:]],
                "serverInfo": [
                    "name": "DebugBridge",
                    "version": "2.0.0",
                    "device": UIDevice.current.name,
                    "model": UIDevice.current.model,
                    "systemVersion": UIDevice.current.systemVersion
                ]
            ] as [String: Any]))

        case "notifications/initialized":
            return // no response needed

        case "tools/list":
            let toolList = tools.values.map { tool -> [String: Any] in
                [
                    "name": tool.name,
                    "description": tool.description,
                    "inputSchema": tool.inputSchema
                ]
            }
            response = JSONRPCResponse(id: request.id, result: AnyCodable(["tools": toolList]))

        case "tools/call":
            let params = request.params.flatMap { dict -> [String: Any]? in
                dict.mapValues(\.value) as [String: Any]
            } ?? [:]
            let toolName = (params["name"] as? String) ?? ""
            let toolArgs = (params["arguments"] as? [String: Any]) ?? [:]

            if let tool = tools[toolName] {
                let result = await tool.handler(toolArgs)
                response = JSONRPCResponse(id: request.id, result: AnyCodable([
                    "content": [["type": "text", "text": String(describing: result)]]
                ] as [String: Any]))
            } else {
                response = JSONRPCResponse(
                    id: request.id,
                    error: JSONRPCError(code: -32601, message: "Unknown tool: \(toolName)")
                )
            }

        case "ping":
            response = JSONRPCResponse(id: request.id, result: AnyCodable([:] as [String: Any]))

        default:
            response = JSONRPCResponse(
                id: request.id,
                error: JSONRPCError(code: -32601, message: "Method not found: \(request.method)")
            )
        }

        sendResponse(response, on: connection)
    }

    private func sendResponse(_ response: JSONRPCResponse, on connection: NWConnection) {
        guard let data = try? JSONEncoder().encode(response) else { return }

        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(
            identifier: "response",
            metadata: [metadata]
        )
        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }
}

#endif
