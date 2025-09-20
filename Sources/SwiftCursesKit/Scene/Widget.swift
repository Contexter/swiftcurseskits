import Foundation

/// Describes a renderable widget that can participate in layout.
public protocol Widget: Sendable {
    /// Measures the widget within the provided constraints.
    func measure(in constraints: LayoutConstraints) -> LayoutSize

    /// Emits draw commands covering the supplied frame.
    func render(in frame: LayoutRect, buffer: inout RenderBuffer)
}

/// Type erasure for ``Widget`` values.
public struct AnyWidget: Sendable {
    private let measureClosure: @Sendable (LayoutConstraints) -> LayoutSize
    private let renderClosure: @Sendable (LayoutRect, inout RenderBuffer) -> Void

    public init<W: Widget>(_ widget: W) {
        measureClosure = { widget.measure(in: $0) }
        renderClosure = { frame, buffer in
            widget.render(in: frame, buffer: &buffer)
        }
    }

    public func measure(in constraints: LayoutConstraints) -> LayoutSize {
        measureClosure(constraints)
    }

    public func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
        renderClosure(frame, &buffer)
    }
}
