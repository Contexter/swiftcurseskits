import Foundation

/// Represents a declarative scene that can be composed through ``SceneBuilder``.
public protocol Scene: Sendable {
    func makeSceneNodes() -> [SceneNode]
}

/// A scene that wraps a single node.
public struct SingleScene: Scene {
    private let node: SceneNode

    public init(node: SceneNode) {
        self.node = node
    }

    public func makeSceneNodes() -> [SceneNode] { [node] }
}

/// A scene representing a list of child nodes.
public struct SceneCollection: Scene {
    public var nodes: [SceneNode]

    public init(nodes: [SceneNode]) {
        self.nodes = nodes
    }

    public func makeSceneNodes() -> [SceneNode] { nodes }
}

public extension Scene {
    private func mapNodes(_ transform: (SceneNode) -> SceneNode) -> Scene {
        SceneCollection(nodes: makeSceneNodes().map(transform))
    }

    func padding(_ value: Int) -> Scene {
        padding(LayoutPadding(top: value, leading: value, bottom: value, trailing: value))
    }

    func padding(_ padding: LayoutPadding) -> Scene {
        mapNodes { node in
            var node = node
            let existing = node.modifiers.padding
            node.modifiers.padding = LayoutPadding(
                top: existing.top + padding.top,
                leading: existing.leading + padding.leading,
                bottom: existing.bottom + padding.bottom,
                trailing: existing.trailing + padding.trailing
            )
            return node
        }
    }
}

/// A result builder that translates declarative scene declarations into
/// ``SceneNode`` trees.
@resultBuilder
public enum SceneBuilder {
    public static func buildBlock(_ components: Scene...) -> SceneCollection {
        SceneCollection(nodes: components.flatMap { $0.makeSceneNodes() })
    }

    public static func buildOptional(_ component: Scene?) -> SceneCollection {
        component.map { SceneCollection(nodes: $0.makeSceneNodes()) } ?? SceneCollection(nodes: [])
    }

    public static func buildEither(first component: Scene) -> SceneCollection {
        SceneCollection(nodes: component.makeSceneNodes())
    }

    public static func buildEither(second component: Scene) -> SceneCollection {
        SceneCollection(nodes: component.makeSceneNodes())
    }

    public static func buildArray(_ components: [SceneCollection]) -> SceneCollection {
        SceneCollection(nodes: components.flatMap { $0.nodes })
    }

    public static func buildExpression(_ expression: SceneNode) -> SceneCollection {
        SceneCollection(nodes: [expression])
    }

    public static func buildExpression(_ expression: Scene) -> SceneCollection {
        SceneCollection(nodes: expression.makeSceneNodes())
    }

    public static func buildFinalResult(_ component: SceneCollection) -> SceneCollection {
        component
    }
}

extension SceneNode: Scene {
    public func makeSceneNodes() -> [SceneNode] { [self] }
}
