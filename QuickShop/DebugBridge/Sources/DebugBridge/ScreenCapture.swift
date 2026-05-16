import UIKit

#if DEBUG

@MainActor
public enum ScreenCapture {

    public static func registerTools(on server: MCPServer) {
        server.registerTool(MCPToolDefinition(
            name: "screenshot",
            description: "Capture the current screen as a base64-encoded PNG image.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "scale": ["type": "number", "description": "Scale factor (default 1.0, use 0.5 for smaller images)"]
                ] as [String: Any],
                "required": [] as [String]
            ] as [String: Any],
            handler: { args in
                let scale = args["scale"] as? Double ?? 1.0
                return await captureScreen(scale: CGFloat(scale))
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "screenshot_region",
            description: "Capture a region of the screen. Coordinates are normalized (0.0-1.0).",
            inputSchema: [
                "type": "object",
                "properties": [
                    "x": ["type": "number", "description": "Left edge (0.0-1.0)"],
                    "y": ["type": "number", "description": "Top edge (0.0-1.0)"],
                    "width": ["type": "number", "description": "Width (0.0-1.0)"],
                    "height": ["type": "number", "description": "Height (0.0-1.0)"]
                ] as [String: Any],
                "required": ["x", "y", "width", "height"]
            ] as [String: Any],
            handler: { args in
                guard let x = args["x"] as? Double,
                      let y = args["y"] as? Double,
                      let width = args["width"] as? Double,
                      let height = args["height"] as? Double else {
                    return "ERROR: x, y, width, height required"
                }
                return await captureRegion(
                    normalizedRect: CGRect(x: x, y: y, width: width, height: height)
                )
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "device_info",
            description: "Get device information (model, screen size, OS version, app state).",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                return await getDeviceInfo()
            }
        ))
    }

    // MARK: - Full Screen Capture

    private static func captureScreen(scale: CGFloat) async -> String {
        guard let window = getKeyWindow() else {
            return "ERROR: no key window"
        }

        let renderer = UIGraphicsImageRenderer(
            size: window.bounds.size,
            format: {
                let format = UIGraphicsImageRendererFormat()
                format.scale = UIScreen.main.scale * scale
                return format
            }()
        )

        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }

        guard let pngData = image.pngData() else {
            return "ERROR: failed to generate PNG"
        }

        let base64 = pngData.base64EncodedString()
        return "{\"type\": \"image\", \"format\": \"png\", \"encoding\": \"base64\", \"width\": \(Int(window.bounds.width)), \"height\": \(Int(window.bounds.height)), \"data\": \"\(base64)\"}"
    }

    // MARK: - Region Capture

    private static func captureRegion(normalizedRect: CGRect) async -> String {
        guard let window = getKeyWindow() else {
            return "ERROR: no key window"
        }

        let screenSize = window.bounds.size
        let pixelRect = CGRect(
            x: normalizedRect.origin.x * screenSize.width,
            y: normalizedRect.origin.y * screenSize.height,
            width: normalizedRect.size.width * screenSize.width,
            height: normalizedRect.size.height * screenSize.height
        )

        let renderer = UIGraphicsImageRenderer(
            size: window.bounds.size,
            format: {
                let format = UIGraphicsImageRendererFormat()
                format.scale = UIScreen.main.scale
                return format
            }()
        )

        let fullImage = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }

        // Crop to region
        let scaledRect = CGRect(
            x: pixelRect.origin.x * UIScreen.main.scale,
            y: pixelRect.origin.y * UIScreen.main.scale,
            width: pixelRect.size.width * UIScreen.main.scale,
            height: pixelRect.size.height * UIScreen.main.scale
        )

        guard let cgImage = fullImage.cgImage?.cropping(to: scaledRect) else {
            return "ERROR: failed to crop"
        }

        let croppedImage = UIImage(cgImage: cgImage)
        guard let pngData = croppedImage.pngData() else {
            return "ERROR: failed to encode cropped region"
        }

        let base64 = pngData.base64EncodedString()
        return "{\"type\": \"image\", \"format\": \"png\", \"encoding\": \"base64\", \"width\": \(Int(pixelRect.width)), \"height\": \(Int(pixelRect.height)), \"data\": \"\(base64)\"}"
    }

    // MARK: - Device Info

    private static func getDeviceInfo() async -> String {
        let device = UIDevice.current
        let screen = UIScreen.main
        let window = getKeyWindow()

        let info: [String: Any] = [
            "device": [
                "name": device.name,
                "model": device.model,
                "systemName": device.systemName,
                "systemVersion": device.systemVersion
            ],
            "screen": [
                "width": screen.bounds.width,
                "height": screen.bounds.height,
                "scale": screen.scale,
                "safeAreaTop": window?.safeAreaInsets.top ?? 0,
                "safeAreaBottom": window?.safeAreaInsets.bottom ?? 0
            ],
            "app": [
                "bundleId": Bundle.main.bundleIdentifier ?? "unknown",
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown",
                "build": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown"
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }

    // MARK: - Helpers

    private static func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}

#endif
