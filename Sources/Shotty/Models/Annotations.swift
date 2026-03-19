import AppKit
import CoreGraphics
import Foundation
import SwiftUI

enum AnnotationTool: String, CaseIterable, Identifiable {
    case text
    case pencil
    case rectangle
    case circle
    case highlight
    case arrow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:
            return "Text"
        case .pencil:
            return "Pencil"
        case .rectangle:
            return "Rectangle"
        case .circle:
            return "Circle"
        case .highlight:
            return "Highlight"
        case .arrow:
            return "Arrow"
        }
    }

    var shortDescription: String {
        switch self {
        case .text:
            return "Click to place editable text"
        case .pencil:
            return "Draw smooth freehand strokes"
        case .rectangle:
            return "Drag out a stroked box"
        case .circle:
            return "Drag out a stroked ellipse"
        case .highlight:
            return "Transparent marker-style stroke"
        case .arrow:
            return "Drag out a directional arrow"
        }
    }

    var symbolName: String {
        switch self {
        case .text:
            return "character.cursor.ibeam"
        case .pencil:
            return "pencil.line"
        case .rectangle:
            return "square"
        case .circle:
            return "circle"
        case .highlight:
            return "highlighter"
        case .arrow:
            return "arrow.up.right"
        }
    }

    var defaultColorToken: AnnotationColorToken {
        switch self {
        case .text:
            return .white
        case .pencil, .rectangle:
            return .purple
        case .circle:
            return .gold
        case .highlight:
            return .pink
        case .arrow:
            return .cyan
        }
    }

    var defaultSizePreset: AnnotationSizePreset {
        .m
    }

    var shortcutIndex: Int {
        switch self {
        case .text:
            return 1
        case .pencil:
            return 2
        case .rectangle:
            return 3
        case .circle:
            return 4
        case .highlight:
            return 5
        case .arrow:
            return 6
        }
    }
}

enum AnnotationColorToken: String, Codable, CaseIterable {
    case purple
    case pink
    case cyan
    case gold
    case white
    case red

    var color: Color {
        Color(nsColor: nsColor)
    }

    var title: String {
        rawValue.capitalized
    }

    var nsColor: NSColor {
        switch self {
        case .purple:
            return .init(red: 0.706, green: 0.302, blue: 1.0, alpha: 1)
        case .pink:
            return .init(red: 1.0, green: 0.349, blue: 0.839, alpha: 1)
        case .cyan:
            return .init(red: 0.0, green: 0.898, blue: 1.0, alpha: 1)
        case .gold:
            return .init(red: 1.0, green: 0.847, blue: 0.302, alpha: 1)
        case .white:
            return .init(white: 0.98, alpha: 1)
        case .red:
            return .init(red: 1.0, green: 0.220, blue: 0.376, alpha: 1)
        }
    }
}

enum AnnotationSizePreset: String, Codable, CaseIterable, Identifiable {
    case xs
    case s
    case m
    case l
    case xl

    var id: String { rawValue }

    var title: String {
        rawValue
    }

    var textFontSize: CGFloat {
        switch self {
        case .xs:
            return 14
        case .s:
            return 18
        case .m:
            return 22
        case .l:
            return 28
        case .xl:
            return 36
        }
    }

    func lineWidth(for tool: AnnotationTool) -> CGFloat {
        switch tool {
        case .text:
            return textFontSize
        case .pencil:
            switch self {
            case .xs: return 2.5
            case .s: return 4
            case .m: return 6
            case .l: return 8
            case .xl: return 11
            }
        case .rectangle, .circle:
            switch self {
            case .xs: return 3
            case .s: return 5
            case .m: return 7
            case .l: return 9
            case .xl: return 12
            }
        case .highlight:
            switch self {
            case .xs: return 10
            case .s: return 14
            case .m: return 18
            case .l: return 24
            case .xl: return 30
            }
        case .arrow:
            switch self {
            case .xs: return 3
            case .s: return 5
            case .m: return 7
            case .l: return 9
            case .xl: return 12
            }
        }
    }
}

struct AnnotationToolStyle: Equatable {
    var colorToken: AnnotationColorToken
    var sizePreset: AnnotationSizePreset

    init(
        colorToken: AnnotationColorToken,
        sizePreset: AnnotationSizePreset
    ) {
        self.colorToken = colorToken
        self.sizePreset = sizePreset
    }
}

struct TextAnnotation: Identifiable, Equatable {
    var id = UUID()
    var color: AnnotationColorToken = .white
    var text: String
    var origin: CGPoint
    var fontSize: CGFloat = 30

    var textBounds: CGRect {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        ]
        let displayString = text.isEmpty ? "Text" : text
        let measuredSize = (displayString as NSString).size(withAttributes: attributes)
        let size = CGSize(
            width: ceil(measuredSize.width),
            height: ceil(measuredSize.height)
        )

        return CGRect(origin: origin, size: size)
    }
}

struct PathAnnotation: Identifiable, Equatable {
    var id = UUID()
    var color: AnnotationColorToken = .purple
    var points: [CGPoint]
    var lineWidth: CGFloat = 4

    var bounds: CGRect {
        strokedBounds(for: points, lineWidth: lineWidth)
    }
}

struct RectAnnotation: Identifiable, Equatable {
    var id = UUID()
    var color: AnnotationColorToken = .purple
    var rect: CGRect
    var lineWidth: CGFloat = 5

    var bounds: CGRect {
        rect.standardized.insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2)
    }
}

struct EllipseAnnotation: Identifiable, Equatable {
    var id = UUID()
    var color: AnnotationColorToken = .gold
    var rect: CGRect
    var lineWidth: CGFloat = 5

    var bounds: CGRect {
        rect.standardized.insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2)
    }
}

struct HighlightAnnotation: Identifiable, Equatable {
    var id = UUID()
    var color: AnnotationColorToken = .gold
    var points: [CGPoint]
    var lineWidth: CGFloat = 18

    var bounds: CGRect {
        strokedBounds(for: points, lineWidth: lineWidth)
    }
}

struct ArrowAnnotation: Identifiable, Equatable {
    var id = UUID()
    var color: AnnotationColorToken = .cyan
    var start: CGPoint
    var end: CGPoint
    var lineWidth: CGFloat = 7

    var bounds: CGRect {
        strokedArrowBounds(start: start, end: end, lineWidth: lineWidth)
    }
}

enum AnnotationSnapshot: Identifiable, Equatable {
    case text(TextAnnotation)
    case path(PathAnnotation)
    case rect(RectAnnotation)
    case ellipse(EllipseAnnotation)
    case highlight(HighlightAnnotation)
    case arrow(ArrowAnnotation)

    var id: UUID {
        switch self {
        case let .text(annotation):
            return annotation.id
        case let .path(annotation):
            return annotation.id
        case let .rect(annotation):
            return annotation.id
        case let .ellipse(annotation):
            return annotation.id
        case let .highlight(annotation):
            return annotation.id
        case let .arrow(annotation):
            return annotation.id
        }
    }

    var tool: AnnotationTool {
        switch self {
        case .text:
            return .text
        case .path:
            return .pencil
        case .rect:
            return .rectangle
        case .ellipse:
            return .circle
        case .highlight:
            return .highlight
        case .arrow:
            return .arrow
        }
    }

    var selectionBounds: CGRect {
        switch self {
        case let .text(annotation):
            return annotation.textBounds.insetBy(dx: -8, dy: -6)
        case let .path(annotation):
            return annotation.bounds.insetBy(dx: -8, dy: -8)
        case let .rect(annotation):
            return annotation.bounds.insetBy(dx: -6, dy: -6)
        case let .ellipse(annotation):
            return annotation.bounds.insetBy(dx: -6, dy: -6)
        case let .highlight(annotation):
            return annotation.bounds.insetBy(dx: -10, dy: -10)
        case let .arrow(annotation):
            return annotation.bounds.insetBy(dx: -8, dy: -8)
        }
    }

    var textValue: String? {
        guard case let .text(annotation) = self else { return nil }
        return annotation.text
    }

    func hitTest(_ point: CGPoint, tolerance: CGFloat = 10) -> Bool {
        switch self {
        case let .text(annotation):
            return annotation.textBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case let .path(annotation):
            return strokedPathContains(
                points: annotation.points,
                lineWidth: annotation.lineWidth + (tolerance * 2),
                point: point
            )
        case let .rect(annotation):
            return annotation.rect.standardized.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case let .ellipse(annotation):
            return ellipseContains(
                rect: annotation.rect.standardized.insetBy(dx: -tolerance, dy: -tolerance),
                point: point
            )
        case let .highlight(annotation):
            return strokedPathContains(
                points: annotation.points,
                lineWidth: annotation.lineWidth + (tolerance * 2),
                point: point
            )
        case let .arrow(annotation):
            return strokedArrowContains(
                start: annotation.start,
                end: annotation.end,
                lineWidth: annotation.lineWidth + (tolerance * 2),
                point: point
            )
        }
    }

    func updatedText(_ text: String) -> AnnotationSnapshot {
        guard case var .text(annotation) = self else { return self }
        annotation.text = text
        return .text(annotation)
    }

    static func makeText(
        at origin: CGPoint,
        color: AnnotationColorToken = .white,
        fontSize: CGFloat = AnnotationSizePreset.m.textFontSize
    ) -> AnnotationSnapshot {
        .text(
            TextAnnotation(
                color: color,
                text: "",
                origin: origin,
                fontSize: fontSize
            )
        )
    }

    static func makePath(
        points: [CGPoint],
        color: AnnotationColorToken = .purple,
        lineWidth: CGFloat = AnnotationSizePreset.m.lineWidth(for: .pencil)
    ) -> AnnotationSnapshot? {
        guard points.count > 1 else { return nil }

        return .path(
            PathAnnotation(
                color: color,
                points: points,
                lineWidth: lineWidth
            )
        )
    }

    static func makeHighlight(
        points: [CGPoint],
        color: AnnotationColorToken = .pink,
        lineWidth: CGFloat = AnnotationSizePreset.m.lineWidth(for: .highlight)
    ) -> AnnotationSnapshot? {
        guard points.count > 1 else { return nil }

        return .highlight(
            HighlightAnnotation(
                color: color,
                points: points,
                lineWidth: lineWidth
            )
        )
    }

    static func makeRectangle(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColorToken = .purple,
        lineWidth: CGFloat = AnnotationSizePreset.m.lineWidth(for: .rectangle)
    ) -> AnnotationSnapshot? {
        let rect = CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y).standardized
        guard rect.width >= 4, rect.height >= 4 else { return nil }

        return .rect(RectAnnotation(color: color, rect: rect, lineWidth: lineWidth))
    }

    static func makeEllipse(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColorToken = .gold,
        lineWidth: CGFloat = AnnotationSizePreset.m.lineWidth(for: .circle)
    ) -> AnnotationSnapshot? {
        let rect = CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y).standardized
        guard rect.width >= 4, rect.height >= 4 else { return nil }

        return .ellipse(EllipseAnnotation(color: color, rect: rect, lineWidth: lineWidth))
    }

    static func makeArrow(
        from start: CGPoint,
        to end: CGPoint,
        color: AnnotationColorToken = .cyan,
        lineWidth: CGFloat = AnnotationSizePreset.m.lineWidth(for: .arrow)
    ) -> AnnotationSnapshot? {
        guard hypot(end.x - start.x, end.y - start.y) >= 6 else { return nil }

        return .arrow(
            ArrowAnnotation(
                color: color,
                start: start,
                end: end,
                lineWidth: lineWidth
            )
        )
    }
}

private func strokedBounds(for points: [CGPoint], lineWidth: CGFloat) -> CGRect {
    guard points.isEmpty == false else { return .null }
    return smoothedPath(for: points)
        .copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)
        .boundingBoxOfPath
}

private func strokedPathContains(points: [CGPoint], lineWidth: CGFloat, point: CGPoint) -> Bool {
    guard points.count > 1 else { return false }

    let strokedPath = smoothedPath(for: points)
        .copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)

    return strokedPath.contains(point)
}

private func strokedArrowBounds(start: CGPoint, end: CGPoint, lineWidth: CGFloat) -> CGRect {
    arrowPath(from: start, to: end, lineWidth: lineWidth)
        .copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)
        .boundingBoxOfPath
}

private func strokedArrowContains(start: CGPoint, end: CGPoint, lineWidth: CGFloat, point: CGPoint) -> Bool {
    let strokedPath = arrowPath(from: start, to: end, lineWidth: lineWidth)
        .copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)

    return strokedPath.contains(point)
}

private func ellipseContains(rect: CGRect, point: CGPoint) -> Bool {
    guard rect.isEmpty == false else { return false }

    let normalizedX = (point.x - rect.midX) / max(rect.width / 2, 0.01)
    let normalizedY = (point.y - rect.midY) / max(rect.height / 2, 0.01)

    return (normalizedX * normalizedX) + (normalizedY * normalizedY) <= 1
}

func smoothedPath(for points: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    guard let firstPoint = points.first else { return path }

    if points.count == 1 {
        path.addEllipse(in: CGRect(x: firstPoint.x - 0.5, y: firstPoint.y - 0.5, width: 1, height: 1))
        return path
    }

    path.move(to: firstPoint)

    if points.count == 2 {
        path.addLine(to: points[1])
        return path
    }

    for index in 1..<(points.count - 1) {
        let current = points[index]
        let next = points[index + 1]
        let midpoint = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)
        path.addQuadCurve(to: midpoint, control: current)
    }

    if let lastPoint = points.last {
        path.addLine(to: lastPoint)
    }

    return path
}

func arrowPath(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: start)
    path.addLine(to: end)

    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = max(hypot(dx, dy), 0.01)
    let unitX = dx / length
    let unitY = dy / length
    let arrowHeadLength = min(max(lineWidth * 3.6, 14), length * 0.6)
    let arrowAngle = CGFloat.pi / 7

    let sinAngle = sin(arrowAngle)
    let cosAngle = cos(arrowAngle)

    let leftX = (unitX * cosAngle) - (unitY * sinAngle)
    let leftY = (unitX * sinAngle) + (unitY * cosAngle)
    let rightX = (unitX * cosAngle) + (unitY * sinAngle)
    let rightY = (-unitX * sinAngle) + (unitY * cosAngle)

    let leftPoint = CGPoint(
        x: end.x - (leftX * arrowHeadLength),
        y: end.y - (leftY * arrowHeadLength)
    )
    let rightPoint = CGPoint(
        x: end.x - (rightX * arrowHeadLength),
        y: end.y - (rightY * arrowHeadLength)
    )

    path.move(to: end)
    path.addLine(to: leftPoint)
    path.move(to: end)
    path.addLine(to: rightPoint)

    return path
}
