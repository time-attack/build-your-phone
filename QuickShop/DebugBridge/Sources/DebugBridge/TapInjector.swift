import UIKit
import SwiftUI

#if DEBUG

@MainActor
public enum TapInjector {

    // MARK: - Register MCP Tools

    public static func registerTools(on server: MCPServer) {
        server.registerTool(MCPToolDefinition(
            name: "tap",
            description: "Tap at normalized coordinates (0.0-1.0). Finds the accessibility element at that point and activates it.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "x": ["type": "number", "description": "X coordinate (0.0 = left, 1.0 = right)"],
                    "y": ["type": "number", "description": "Y coordinate (0.0 = top, 1.0 = bottom)"]
                ] as [String: Any],
                "required": ["x", "y"]
            ] as [String: Any],
            handler: { args in
                guard let x = args["x"] as? Double,
                      let y = args["y"] as? Double else {
                    return "ERROR: x and y required (0.0-1.0)"
                }
                return await performTap(normalizedX: x, normalizedY: y)
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "tap_element",
            description: "Tap an element by its accessibility label. More reliable than coordinate taps for SwiftUI.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "label": ["type": "string", "description": "Accessibility label text (case-insensitive partial match)"],
                    "index": ["type": "number", "description": "0-based index when multiple elements match (default 0)"]
                ] as [String: Any],
                "required": ["label"]
            ] as [String: Any],
            handler: { args in
                guard let label = args["label"] as? String else {
                    return "ERROR: label is required"
                }
                let index = (args["index"] as? Int) ?? (args["index"] as? Double).map { Int($0) } ?? 0
                return await performTapByLabel(label, index: index)
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "swipe",
            description: "Swipe from one point to another. Coordinates normalized (0.0-1.0).",
            inputSchema: [
                "type": "object",
                "properties": [
                    "fromX": ["type": "number"],
                    "fromY": ["type": "number"],
                    "toX": ["type": "number"],
                    "toY": ["type": "number"],
                    "duration": ["type": "number", "description": "Seconds (default 0.3)"]
                ] as [String: Any],
                "required": ["fromX", "fromY", "toX", "toY"]
            ] as [String: Any],
            handler: { args in
                guard let fromX = args["fromX"] as? Double,
                      let fromY = args["fromY"] as? Double,
                      let toX = args["toX"] as? Double,
                      let toY = args["toY"] as? Double else {
                    return "ERROR: fromX, fromY, toX, toY required"
                }
                let duration = args["duration"] as? Double ?? 0.3
                return await performSwipe(
                    fromNormalized: CGPoint(x: fromX, y: fromY),
                    toNormalized: CGPoint(x: toX, y: toY),
                    duration: duration
                )
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "type_text",
            description: "Type text into the currently focused text field.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": ["type": "string", "description": "Text to type"]
                ] as [String: Any],
                "required": ["text"]
            ] as [String: Any],
            handler: { args in
                guard let text = args["text"] as? String else {
                    return "ERROR: text required"
                }
                return await typeText(text)
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "list_elements",
            description: "List all accessible UI elements on screen with labels, frames, and traits.",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                return await listAccessibleElements()
            }
        ))
    }

    // MARK: - Tap by Coordinates

    private static func performTap(normalizedX: Double, normalizedY: Double) async -> String {
        guard let window = getKeyWindow() else { return "ERROR: no key window" }

        let screenSize = window.bounds.size
        let point = CGPoint(
            x: normalizedX * screenSize.width,
            y: normalizedY * screenSize.height
        )

        showTapIndicator(at: point, in: window)
        DebugBridgeNotifier.action("tap (\(String(format: "%.2f", normalizedX)), \(String(format: "%.2f", normalizedY)))")

        // Strategy: find accessibility elements whose frame contains this point,
        // pick the smallest (most specific), and activate it.
        var candidates: [(view: UIView, frame: CGRect)] = []
        collectTappableViews(from: window, point: point, into: &candidates)

        // Sort by area — smallest first = most specific element
        candidates.sort { ($0.frame.width * $0.frame.height) < ($1.frame.width * $1.frame.height) }

        for (view, _) in candidates {
            if view.accessibilityActivate() {
                return "OK: activated \"\(view.accessibilityLabel ?? String(describing: type(of: view)))\""
            }
        }

        // Fallback: try hitTest + UIControl chain
        if let hitView = window.hitTest(point, with: nil) {
            if let control = findControl(from: hitView) {
                control.sendActions(for: .touchUpInside)
                return "OK: triggered control \(type(of: control))"
            }
            if hitView.accessibilityActivate() {
                return "OK: accessibility activated \(type(of: hitView))"
            }
        }

        return "OK: tap at (\(normalizedX), \(normalizedY)) — no activatable element found"
    }

    // MARK: - Tap by Label

    private static func performTapByLabel(_ label: String, index: Int) async -> String {
        guard let window = getKeyWindow() else { return "ERROR: no key window" }

        var matches: [(view: UIView, frame: CGRect, label: String)] = []
        collectViewsByLabel(from: window, searchLabel: label, into: &matches)

        guard !matches.isEmpty else {
            return "ERROR: no element found with label containing \"\(label)\""
        }

        guard index < matches.count else {
            return "ERROR: index \(index) out of range (found \(matches.count) matches)"
        }

        let match = matches[index]
        let center = CGPoint(x: match.frame.midX, y: match.frame.midY)

        showTapIndicator(at: center, in: window)
        DebugBridgeNotifier.action("tap \"\(match.label)\"")

        if match.view.accessibilityActivate() {
            return "OK: activated \"\(match.label)\" (index \(index) of \(matches.count))"
        }

        // Fallback: try parent controls
        if let control = findControl(from: match.view) {
            control.sendActions(for: .touchUpInside)
            return "OK: triggered parent control for \"\(match.label)\""
        }

        return "PARTIAL: found \"\(match.label)\" but activation failed — try tap at (\(String(format: "%.3f", center.x / window.bounds.width)), \(String(format: "%.3f", center.y / window.bounds.height)))"
    }

    // MARK: - Swipe

    private static func performSwipe(
        fromNormalized: CGPoint,
        toNormalized: CGPoint,
        duration: Double
    ) async -> String {
        guard let window = getKeyWindow() else { return "ERROR: no key window" }

        let screenSize = window.bounds.size
        let from = CGPoint(x: fromNormalized.x * screenSize.width, y: fromNormalized.y * screenSize.height)
        let to = CGPoint(x: toNormalized.x * screenSize.width, y: toNormalized.y * screenSize.height)

        showSwipeIndicator(from: from, to: to, in: window)
        DebugBridgeNotifier.action("swipe")

        if let scrollView = findScrollView(at: from, in: window) {
            let dx = to.x - from.x
            let dy = to.y - from.y
            let newOffset = CGPoint(
                x: scrollView.contentOffset.x - dx,
                y: scrollView.contentOffset.y - dy
            )
            scrollView.setContentOffset(newOffset, animated: true)
            return "OK: scrolled by (\(dx), \(dy))"
        }

        return "OK: swipe performed — no scroll view found at start point"
    }

    // MARK: - Type Text

    private static func typeText(_ text: String) async -> String {
        guard let window = getKeyWindow() else { return "ERROR: no key window" }
        guard let responder = findFirstResponder(in: window) else {
            return "ERROR: no focused text field"
        }

        if let keyInput = responder as? UIKeyInput {
            keyInput.insertText(text)
            DebugBridgeNotifier.action("type text")
            return "OK: typed \"\(text)\""
        }

        return "ERROR: focused element doesn't accept text input"
    }

    // MARK: - List Elements

    private static func listAccessibleElements() async -> String {
        guard let window = getKeyWindow() else { return "ERROR: no key window" }

        var elements: [[String: Any]] = []
        collectAccessibleElements(from: window, into: &elements)

        if let data = try? JSONSerialization.data(withJSONObject: elements, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }

    // MARK: - View Collection Helpers

    /// Find views with accessibility info whose frame contains the given point
    private static func collectTappableViews(from view: UIView, point: CGPoint, into results: inout [(view: UIView, frame: CGRect)]) {
        let frame = view.convert(view.bounds, to: nil)

        if frame.contains(point) &&
           (view.isAccessibilityElement || view.accessibilityLabel != nil) &&
           view.isUserInteractionEnabled &&
           !view.isHidden &&
           view.alpha > 0 {
            results.append((view: view, frame: frame))
        }

        for subview in view.subviews {
            collectTappableViews(from: subview, point: point, into: &results)
        }
    }

    /// Find views whose accessibility label contains the search string
    private static func collectViewsByLabel(from view: UIView, searchLabel: String, into results: inout [(view: UIView, frame: CGRect, label: String)]) {
        if let viewLabel = view.accessibilityLabel,
           viewLabel.localizedCaseInsensitiveContains(searchLabel),
           !view.isHidden,
           view.alpha > 0 {
            let frame = view.convert(view.bounds, to: nil)
            results.append((view: view, frame: frame, label: viewLabel))
        }

        for subview in view.subviews {
            collectViewsByLabel(from: subview, searchLabel: searchLabel, into: &results)
        }
    }

    /// Walk up from a view to find a UIControl ancestor
    private static func findControl(from view: UIView) -> UIControl? {
        var current: UIView? = view
        while let v = current {
            if let control = v as? UIControl {
                return control
            }
            current = v.superview
        }
        return nil
    }

    /// Find the first UIScrollView at or above the given point
    private static func findScrollView(at point: CGPoint, in window: UIWindow) -> UIScrollView? {
        var view = window.hitTest(point, with: nil)
        while let current = view {
            if let scroll = current as? UIScrollView { return scroll }
            view = current.superview
        }
        return nil
    }

    /// Find the current first responder
    private static func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let found = findFirstResponder(in: subview) { return found }
        }
        return nil
    }

    /// Collect all accessible elements for list_elements
    private static func collectAccessibleElements(from view: UIView, into elements: inout [[String: Any]]) {
        if view.isAccessibilityElement || view.accessibilityLabel != nil {
            let frame = view.convert(view.bounds, to: nil)
            let screenSize = getKeyWindow()?.bounds.size ?? CGSize(width: 393, height: 852)

            var el: [String: Any] = [
                "type": String(describing: type(of: view)),
                "frame": [
                    "x": frame.origin.x / screenSize.width,
                    "y": frame.origin.y / screenSize.height,
                    "width": frame.size.width / screenSize.width,
                    "height": frame.size.height / screenSize.height
                ]
            ]

            if let label = view.accessibilityLabel { el["label"] = label }
            if let value = view.accessibilityValue { el["value"] = value }
            if let hint = view.accessibilityHint { el["hint"] = hint }
            el["traits"] = describeTraits(view.accessibilityTraits)
            el["enabled"] = view.isUserInteractionEnabled

            elements.append(el)
        }

        for subview in view.subviews {
            collectAccessibleElements(from: subview, into: &elements)
        }
    }

    private static func describeTraits(_ traits: UIAccessibilityTraits) -> [String] {
        var result: [String] = []
        if traits.contains(.button) { result.append("button") }
        if traits.contains(.link) { result.append("link") }
        if traits.contains(.header) { result.append("header") }
        if traits.contains(.staticText) { result.append("staticText") }
        if traits.contains(.image) { result.append("image") }
        if traits.contains(.selected) { result.append("selected") }
        if traits.contains(.notEnabled) { result.append("disabled") }
        return result
    }

    // MARK: - Visual Feedback

    private static func showTapIndicator(at point: CGPoint, in window: UIWindow) {
        let indicator = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.center = point
        indicator.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.3)
        indicator.layer.cornerRadius = 20
        indicator.layer.borderWidth = 2
        indicator.layer.borderColor = UIColor.systemCyan.cgColor
        indicator.isUserInteractionEnabled = false
        window.addSubview(indicator)

        UIView.animate(withDuration: 0.4, animations: {
            indicator.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            indicator.alpha = 0
        }) { _ in
            indicator.removeFromSuperview()
        }
    }

    private static func showSwipeIndicator(from: CGPoint, to: CGPoint, in window: UIWindow) {
        let line = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        line.path = path.cgPath
        line.strokeColor = UIColor.systemCyan.withAlphaComponent(0.5).cgColor
        line.lineWidth = 3
        line.lineCap = .round
        window.layer.addSublayer(line)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            line.removeFromSuperlayer()
        }
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
