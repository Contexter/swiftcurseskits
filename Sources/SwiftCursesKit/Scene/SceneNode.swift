import Foundation

/// Describes a logical element in a declarative scene tree.
public struct SceneNode: Sendable {
    public enum Kind: Sendable {
        case group
        case stack(axis: StackAxis, spacing: Int)
        case split(configuration: SplitConfiguration)
        case widget(AnyWidget)
    }

    public var kind: Kind
    public var children: [SceneNode]
    public var modifiers: SceneModifiers

    public init(kind: Kind, children: [SceneNode] = [], modifiers: SceneModifiers = .default) {
        self.kind = kind
        self.children = children
        self.modifiers = modifiers
    }
}

/// Defines layout modifiers that can be applied to a node.
public struct SceneModifiers: Sendable, Hashable {
    public var padding: LayoutPadding

    public init(padding: LayoutPadding = .zero) {
        self.padding = padding
    }

    public static let `default` = SceneModifiers()
}

/// Represents edge insets expressed in terminal cell units.
public struct LayoutPadding: Sendable, Hashable {
    public var top: Int
    public var leading: Int
    public var bottom: Int
    public var trailing: Int

    public init(top: Int, leading: Int, bottom: Int, trailing: Int) {
        self.top = max(0, top)
        self.leading = max(0, leading)
        self.bottom = max(0, bottom)
        self.trailing = max(0, trailing)
    }

    public static let zero = LayoutPadding(top: 0, leading: 0, bottom: 0, trailing: 0)

    public func inset(size: LayoutSize) -> LayoutSize {
        LayoutSize(
            width: max(0, size.width - leading - trailing),
            height: max(0, size.height - top - bottom)
        )
    }
}

/// Identifies the axis used by stack based layouts.
public enum StackAxis: Sendable {
    case vertical
    case horizontal
}

/// Describes a split layout configuration.
public struct SplitConfiguration: Sendable, Hashable {
    public enum Orientation: Sendable {
        case vertical
        case horizontal
    }

    public var orientation: Orientation
    public var fraction: Double

    public init(orientation: Orientation, fraction: Double) {
        self.orientation = orientation
        self.fraction = min(1.0, max(0.0, fraction))
    }
}
