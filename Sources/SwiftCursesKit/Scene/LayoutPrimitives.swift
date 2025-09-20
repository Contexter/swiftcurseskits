import Foundation

public struct VStack: Scene {
    public var spacing: Int
    private var content: SceneCollection

    public init(spacing: Int = 0, @SceneBuilder content: () -> SceneCollection) {
        self.spacing = max(0, spacing)
        self.content = content()
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .stack(axis: .vertical, spacing: spacing), children: content.nodes)]
    }
}

public struct HStack: Scene {
    public var spacing: Int
    private var content: SceneCollection

    public init(spacing: Int = 1, @SceneBuilder content: () -> SceneCollection) {
        self.spacing = max(0, spacing)
        self.content = content()
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .stack(axis: .horizontal, spacing: spacing), children: content.nodes)]
    }
}

public struct Split: Scene {
    public var configuration: SplitConfiguration
    private var leading: SceneCollection
    private var trailing: SceneCollection

    public init(
        _ orientation: SplitConfiguration.Orientation,
        fraction: Double,
        @SceneBuilder leading: () -> SceneCollection,
        @SceneBuilder trailing: () -> SceneCollection
    ) {
        self.configuration = SplitConfiguration(orientation: orientation, fraction: fraction)
        self.leading = leading()
        self.trailing = trailing()
    }

    public func makeSceneNodes() -> [SceneNode] {
        let leadingGroup = SceneNode(kind: .group, children: leading.nodes)
        let trailingGroup = SceneNode(kind: .group, children: trailing.nodes)
        return [
            SceneNode(
                kind: .split(configuration: configuration), children: [leadingGroup, trailingGroup])
        ]
    }
}

public struct Title: Scene {
    public var text: String

    public init(_ text: String) {
        self.text = text
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .widget(AnyWidget(TitleWidget(text: text))))]
    }
}

public struct Gauge: Scene {
    public var title: String
    public var value: Double

    public init(title: String, value: Double) {
        self.title = title
        self.value = value
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .widget(AnyWidget(GaugeWidget(title: title, value: value))))]
    }
}

public struct LogView: Scene {
    public var lines: [String]
    public var maximumVisibleLines: Int

    public init(lines: [String], maximumVisibleLines: Int = 10) {
        self.lines = lines
        self.maximumVisibleLines = max(1, maximumVisibleLines)
    }

    public func makeSceneNodes() -> [SceneNode] {
        [
            SceneNode(
                kind: .widget(
                    AnyWidget(LogViewWidget(lines: lines, maximumVisibleLines: maximumVisibleLines))
                ))
        ]
    }
}

public struct StatusBar: Scene {
    public struct Item: Sendable, Hashable {
        public var text: String

        public static func label(_ text: String) -> Item {
            Item(text: text)
        }
    }

    public var items: [Item]

    public init(items: [Item]) {
        self.items = items
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .widget(AnyWidget(StatusBarWidget(items: items))))]
    }
}

/// A convenience scene matching the README examples.
public struct ScreenScene: Scene {
    private var content: SceneCollection

    public init(@SceneBuilder content: () -> SceneCollection) {
        self.content = content()
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .group, children: content.nodes)]
    }
}

public func Screen(@SceneBuilder content: () -> SceneCollection) -> ScreenScene {
    ScreenScene(content: content)
}

/// Wraps an arbitrary widget into a scene element for custom extensions.
public struct WidgetScene<W: Widget>: Scene {
    public var widget: W

    public init(_ widget: W) {
        self.widget = widget
    }

    public func makeSceneNodes() -> [SceneNode] {
        [SceneNode(kind: .widget(AnyWidget(widget)))]
    }
}

public func WidgetView<W: Widget>(_ widget: W) -> WidgetScene<W> {
    WidgetScene(widget)
}
