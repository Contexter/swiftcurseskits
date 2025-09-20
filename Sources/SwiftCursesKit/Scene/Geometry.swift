import Foundation

/// Represents a discrete size in terminal cell units.
public struct LayoutSize: Sendable, Hashable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = max(0, width)
        self.height = max(0, height)
    }

    public static let zero = LayoutSize(width: 0, height: 0)
}

/// Represents an origin expressed in terminal cell coordinates.
public struct LayoutPoint: Sendable, Hashable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public static let zero = LayoutPoint(x: 0, y: 0)
}

/// Describes an axis-aligned rectangle inside the terminal grid.
public struct LayoutRect: Sendable, Hashable {
    public var origin: LayoutPoint
    public var size: LayoutSize

    public init(origin: LayoutPoint, size: LayoutSize) {
        self.origin = origin
        self.size = size
    }

    public var minX: Int { origin.x }
    public var minY: Int { origin.y }
    public var maxX: Int { origin.x + size.width }
    public var maxY: Int { origin.y + size.height }
}

/// Defines the measurement constraints provided to layout elements.
public struct LayoutConstraints: Sendable {
    public var minWidth: Int
    public var minHeight: Int
    public var maxWidth: Int
    public var maxHeight: Int

    public init(minWidth: Int = 0, minHeight: Int = 0, maxWidth: Int = .max, maxHeight: Int = .max)
    {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }

    public func clamped(size: LayoutSize) -> LayoutSize {
        LayoutSize(
            width: min(maxWidth, max(minWidth, size.width)),
            height: min(maxHeight, max(minHeight, size.height))
        )
    }
}
