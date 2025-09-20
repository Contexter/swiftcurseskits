import Foundation

struct TitleWidget: Widget {
    var text: String

    func measure(in constraints: LayoutConstraints) -> LayoutSize {
        let width = min(constraints.maxWidth, max(constraints.minWidth, text.count))
        return LayoutSize(width: max(1, width), height: 1)
    }

    func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
        guard frame.size.height > 0, frame.size.width > 0 else { return }
        let truncated = String(text.prefix(frame.size.width))
        buffer.write(truncated, at: frame.origin, maxWidth: frame.size.width)
    }
}

struct GaugeWidget: Widget {
    var title: String
    var value: Double

    func measure(in constraints: LayoutConstraints) -> LayoutSize {
        let width = max(constraints.minWidth, min(constraints.maxWidth, max(12, title.count)))
        let height = max(constraints.minHeight, min(constraints.maxHeight, 3))
        return LayoutSize(width: width, height: height)
    }

    func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
        guard frame.size.width > 0, frame.size.height > 0 else { return }
        let titleLine = String(title.prefix(frame.size.width))
        buffer.write(titleLine, at: frame.origin, maxWidth: frame.size.width)

        if frame.size.height > 1 {
            let progress = max(0.0, min(1.0, value))
            let innerWidth = max(0, frame.size.width - 2)
            let filled = Int((Double(innerWidth) * progress).rounded())
            let empty = max(0, innerWidth - filled)
            let filledBar = String(repeating: "#", count: filled)
            let emptyBar = String(repeating: " ", count: empty)
            let barLine = "[" + filledBar + emptyBar + "]"
            let barOrigin = LayoutPoint(x: frame.origin.x, y: frame.origin.y + 1)
            buffer.write(
                String(barLine.prefix(frame.size.width)), at: barOrigin, maxWidth: frame.size.width)

            if frame.size.height > 2 {
                let percentage = Int((progress * 100).rounded())
                let label = "\(percentage)%"
                let padded = label.padding(toLength: frame.size.width, withPad: " ", startingAt: 0)
                let labelOrigin = LayoutPoint(x: frame.origin.x, y: frame.origin.y + 2)
                buffer.write(
                    String(padded.prefix(frame.size.width)), at: labelOrigin,
                    maxWidth: frame.size.width)
            }
        }
    }
}

struct LogViewWidget: Widget {
    var lines: [String]
    var maximumVisibleLines: Int

    func measure(in constraints: LayoutConstraints) -> LayoutSize {
        let visibleLines = min(maximumVisibleLines, constraints.maxHeight)
        let width = min(
            constraints.maxWidth, max(constraints.minWidth, lines.map { $0.count }.max() ?? 0))
        return LayoutSize(width: max(1, width), height: max(1, visibleLines))
    }

    func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
        guard frame.size.width > 0, frame.size.height > 0 else { return }
        let visibleLines = lines.suffix(frame.size.height)
        let startY = frame.origin.y
        var currentY = startY
        for line in visibleLines {
            let truncated = String(line.prefix(frame.size.width))
            buffer.write(
                truncated, at: LayoutPoint(x: frame.origin.x, y: currentY),
                maxWidth: frame.size.width)
            currentY += 1
        }
    }
}

struct StatusBarWidget: Widget {
    var items: [StatusBar.Item]

    func measure(in constraints: LayoutConstraints) -> LayoutSize {
        LayoutSize(width: constraints.maxWidth, height: 1)
    }

    func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
        guard frame.size.width > 0 else { return }
        let joined = items.map { $0.text }.joined(separator: "   ")
        var padded = joined
        if padded.count < frame.size.width {
            padded = padded.padding(toLength: frame.size.width, withPad: " ", startingAt: 0)
        }
        buffer.write(
            String(padded.prefix(frame.size.width)), at: frame.origin, maxWidth: frame.size.width)
    }
}
