import CNCursesSupport
import Foundation

/// Performs layout and rendering passes for declaratively described scenes.
public struct SceneRenderer: Sendable {
    public init() {}

    public func render(scene: Scene, on screen: TerminalScreen) throws {
        guard let descriptor = screen.rootWindow.withDescriptor({ $0 }) else {
            return
        }
        let size = CNCursesWindowAPI.size(of: descriptor)
        let rootSize = LayoutSize(width: max(0, size.columns), height: max(0, size.rows))
        let rootRect = LayoutRect(origin: .zero, size: rootSize)

        var buffer = RenderBuffer()
        for node in scene.makeSceneNodes() {
            layout(node: node, in: rootRect, buffer: &buffer)
        }

        try CNCursesWindowAPI.clear(descriptor)
        for command in buffer.commands {
            guard command.origin.x >= 0, command.origin.y >= 0 else { continue }
            guard command.origin.y < rootSize.height, command.origin.x < rootSize.width else {
                continue
            }
            let availableWidth = min(command.maxWidth, rootSize.width - command.origin.x)
            guard availableWidth > 0 else { continue }
            let truncated = String(command.text.prefix(availableWidth))
            let padded = truncated.padding(toLength: availableWidth, withPad: " ", startingAt: 0)
            try CNCursesWindowAPI.draw(
                padded, descriptor: descriptor, y: command.origin.y, x: command.origin.x)
        }
        try CNCursesWindowAPI.stage(descriptor)
        try CNCursesWindowAPI.commitStagedUpdates()
    }
}

private extension SceneRenderer {
    func layout(node: SceneNode, in rect: LayoutRect, buffer: inout RenderBuffer) {
        let padding = node.modifiers.padding
        let innerOrigin = LayoutPoint(
            x: rect.origin.x + padding.leading,
            y: rect.origin.y + padding.top
        )
        let innerSize = LayoutSize(
            width: max(0, rect.size.width - padding.leading - padding.trailing),
            height: max(0, rect.size.height - padding.top - padding.bottom)
        )
        let innerRect = LayoutRect(origin: innerOrigin, size: innerSize)
        switch node.kind {
        case .group:
            for child in node.children {
                layout(node: child, in: innerRect, buffer: &buffer)
            }
        case let .stack(axis, spacing):
            layoutStack(axis: axis, spacing: spacing, node: node, in: innerRect, buffer: &buffer)
        case let .split(configuration):
            layoutSplit(configuration: configuration, node: node, in: innerRect, buffer: &buffer)
        case let .widget(widget):
            let constraints = LayoutConstraints(
                maxWidth: innerSize.width, maxHeight: innerSize.height)
            let measured = clampSize(
                widget.measure(in: constraints), to: innerSize, minimum: constraints)
            let frame = LayoutRect(origin: innerOrigin, size: measured)
            widget.render(in: frame, buffer: &buffer)
        }
    }

    func layoutStack(
        axis: StackAxis,
        spacing: Int,
        node: SceneNode,
        in rect: LayoutRect,
        buffer: inout RenderBuffer
    ) {
        guard !node.children.isEmpty else { return }
        let spacingDistance = max(0, spacing)
        switch axis {
        case .vertical:
            let totalSpacing = spacingDistance * max(0, node.children.count - 1)
            let availableHeight = max(0, rect.size.height - totalSpacing)
            var measuredSizes: [LayoutSize] = []
            measuredSizes.reserveCapacity(node.children.count)
            for child in node.children {
                let size = measure(
                    node: child,
                    constraints: LayoutConstraints(
                        maxWidth: rect.size.width, maxHeight: availableHeight)
                )
                measuredSizes.append(size)
            }
            let assignedHeights = distribute(
                available: availableHeight,
                sizes: measuredSizes.map { $0.height }
            )
            var cursorY = rect.origin.y
            for (index, child) in node.children.enumerated() {
                let height = assignedHeights[index]
                guard height > 0 else {
                    cursorY += spacingDistance
                    continue
                }
                let childHeight = min(height, rect.size.height - (cursorY - rect.origin.y))
                let childRect = LayoutRect(
                    origin: LayoutPoint(x: rect.origin.x, y: cursorY),
                    size: LayoutSize(width: rect.size.width, height: childHeight)
                )
                layout(node: child, in: childRect, buffer: &buffer)
                cursorY += childHeight + spacingDistance
            }
        case .horizontal:
            let totalSpacing = spacingDistance * max(0, node.children.count - 1)
            let availableWidth = max(0, rect.size.width - totalSpacing)
            var measuredSizes: [LayoutSize] = []
            measuredSizes.reserveCapacity(node.children.count)
            for child in node.children {
                let size = measure(
                    node: child,
                    constraints: LayoutConstraints(
                        maxWidth: availableWidth, maxHeight: rect.size.height)
                )
                measuredSizes.append(size)
            }
            let assignedWidths = distribute(
                available: availableWidth,
                sizes: measuredSizes.map { $0.width }
            )
            var cursorX = rect.origin.x
            for (index, child) in node.children.enumerated() {
                let width = assignedWidths[index]
                guard width > 0 else {
                    cursorX += spacingDistance
                    continue
                }
                let childWidth = min(width, rect.size.width - (cursorX - rect.origin.x))
                let childRect = LayoutRect(
                    origin: LayoutPoint(x: cursorX, y: rect.origin.y),
                    size: LayoutSize(width: childWidth, height: rect.size.height)
                )
                layout(node: child, in: childRect, buffer: &buffer)
                cursorX += childWidth + spacingDistance
            }
        }
    }

    func layoutSplit(
        configuration: SplitConfiguration,
        node: SceneNode,
        in rect: LayoutRect,
        buffer: inout RenderBuffer
    ) {
        guard node.children.count >= 2 else {
            for child in node.children {
                layout(node: child, in: rect, buffer: &buffer)
            }
            return
        }
        let fraction = max(0.0, min(1.0, configuration.fraction))
        switch configuration.orientation {
        case .vertical:
            let leadingWidth = Int((Double(rect.size.width) * fraction).rounded())
            let trailingWidth = rect.size.width - leadingWidth
            let leadingRect = LayoutRect(
                origin: rect.origin,
                size: LayoutSize(width: max(0, leadingWidth), height: rect.size.height)
            )
            let trailingRect = LayoutRect(
                origin: LayoutPoint(x: rect.origin.x + leadingWidth, y: rect.origin.y),
                size: LayoutSize(width: max(0, trailingWidth), height: rect.size.height)
            )
            layout(node: node.children[0], in: leadingRect, buffer: &buffer)
            layout(node: node.children[1], in: trailingRect, buffer: &buffer)
        case .horizontal:
            let leadingHeight = Int((Double(rect.size.height) * fraction).rounded())
            let trailingHeight = rect.size.height - leadingHeight
            let leadingRect = LayoutRect(
                origin: rect.origin,
                size: LayoutSize(width: rect.size.width, height: max(0, leadingHeight))
            )
            let trailingRect = LayoutRect(
                origin: LayoutPoint(x: rect.origin.x, y: rect.origin.y + leadingHeight),
                size: LayoutSize(width: rect.size.width, height: max(0, trailingHeight))
            )
            layout(node: node.children[0], in: leadingRect, buffer: &buffer)
            layout(node: node.children[1], in: trailingRect, buffer: &buffer)
        }
    }

    func measure(node: SceneNode, constraints: LayoutConstraints) -> LayoutSize {
        let padding = node.modifiers.padding
        let insetConstraints = LayoutConstraints(
            minWidth: max(0, constraints.minWidth - padding.leading - padding.trailing),
            minHeight: max(0, constraints.minHeight - padding.top - padding.bottom),
            maxWidth: max(0, constraints.maxWidth - padding.leading - padding.trailing),
            maxHeight: max(0, constraints.maxHeight - padding.top - padding.bottom)
        )

        let innerSize: LayoutSize
        switch node.kind {
        case .group:
            var width = 0
            var height = 0
            for child in node.children {
                let childSize = measure(node: child, constraints: insetConstraints)
                width = max(width, childSize.width)
                height = max(height, childSize.height)
            }
            innerSize = LayoutSize(width: width, height: height)
        case let .stack(axis, spacing):
            switch axis {
            case .vertical:
                var width = 0
                var height = 0
                for (index, child) in node.children.enumerated() {
                    let childSize = measure(node: child, constraints: insetConstraints)
                    width = max(width, childSize.width)
                    height += childSize.height
                    if index < node.children.count - 1 {
                        height += max(0, spacing)
                    }
                }
                innerSize = LayoutSize(width: width, height: height)
            case .horizontal:
                var width = 0
                var height = 0
                for (index, child) in node.children.enumerated() {
                    let childSize = measure(node: child, constraints: insetConstraints)
                    width += childSize.width
                    if index < node.children.count - 1 {
                        width += max(0, spacing)
                    }
                    height = max(height, childSize.height)
                }
                innerSize = LayoutSize(width: width, height: height)
            }
        case let .split(configuration):
            guard node.children.count >= 2 else {
                let size =
                    node.children.first.map { measure(node: $0, constraints: insetConstraints) }
                    ?? .zero
                innerSize = size
                break
            }
            let leadingSize = measure(node: node.children[0], constraints: insetConstraints)
            let trailingSize = measure(node: node.children[1], constraints: insetConstraints)
            switch configuration.orientation {
            case .vertical:
                innerSize = LayoutSize(
                    width: leadingSize.width + trailingSize.width,
                    height: max(leadingSize.height, trailingSize.height)
                )
            case .horizontal:
                innerSize = LayoutSize(
                    width: max(leadingSize.width, trailingSize.width),
                    height: leadingSize.height + trailingSize.height
                )
            }
        case let .widget(widget):
            innerSize = widget.measure(in: insetConstraints)
        }

        let width = innerSize.width + padding.leading + padding.trailing
        let height = innerSize.height + padding.top + padding.bottom
        return LayoutConstraints(
            minWidth: constraints.minWidth,
            minHeight: constraints.minHeight,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight
        ).clamped(size: LayoutSize(width: width, height: height))
    }

    func distribute(available: Int, sizes: [Int]) -> [Int] {
        guard !sizes.isEmpty else { return [] }
        if available <= 0 {
            return Array(repeating: 0, count: sizes.count)
        }
        var assigned = Array(repeating: 0, count: sizes.count)
        var remaining = available
        for index in sizes.indices {
            let slotsLeft = sizes.count - index
            if slotsLeft <= 0 { break }
            let minimum = max(0, remaining - max(0, slotsLeft - 1) * 1)
            var proposed = remaining / slotsLeft
            if proposed == 0 && remaining > 0 {
                proposed = 1
            }
            proposed = min(proposed, sizes[index])
            proposed = max(minimum, proposed)
            proposed = min(proposed, remaining)
            assigned[index] = proposed
            remaining -= proposed
        }
        return assigned
    }

    func clampSize(_ size: LayoutSize, to bounds: LayoutSize, minimum: LayoutConstraints)
        -> LayoutSize
    {
        let width = min(bounds.width, max(minimum.minWidth, size.width))
        let height = min(bounds.height, max(minimum.minHeight, size.height))
        return LayoutSize(width: width, height: height)
    }
}
