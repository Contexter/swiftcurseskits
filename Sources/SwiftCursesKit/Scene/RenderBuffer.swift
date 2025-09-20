import Foundation

/// Represents a single drawing instruction emitted by a widget.
public struct RenderCommand: Sendable {
    public var origin: LayoutPoint
    public var text: String
    public var maxWidth: Int

    public init(origin: LayoutPoint, text: String, maxWidth: Int) {
        self.origin = origin
        self.text = text
        self.maxWidth = maxWidth
    }
}

/// Collects draw commands during a render pass.
public struct RenderBuffer: Sendable {
    private(set) public var commands: [RenderCommand] = []

    public init() {}

    public mutating func write(_ text: String, at origin: LayoutPoint, maxWidth: Int) {
        guard maxWidth > 0, !text.isEmpty else {
            return
        }
        commands.append(RenderCommand(origin: origin, text: text, maxWidth: maxWidth))
    }
}
