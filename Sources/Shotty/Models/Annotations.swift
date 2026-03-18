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
        }
    }

    var defaultColorToken: AnnotationColorToken {
        switch self {
        case .text:
            return .white
        case .pencil, .rectangle:
            return .purple
        case .circle, .highlight:
            return .gold
        }
    }
}

enum AnnotationColorToken: String, Codable, CaseIterable {
    case purple
    case gold
    case white

    var color: Color {
        Color(nsColor: nsColor)
    }

    var nsColor: NSColor {
        switch self {
        case .purple:
            return .init(red: 0.427, green: 0.157, blue: 0.851, alpha: 1)
        case .gold:
            return .init(red: 1.0, green: 0.847, blue: 0.302, alpha: 1)
        case .white:
            return .init(white: 0.98, alpha: 1)
        }
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

enum AnnotationSnapshot: Identifiable, Equatable {
    case text(TextAnnotation)
    case path(PathAnnotation)
    case rect(RectAnnotation)
    case ellipse(EllipseAnnotation)
    case highlight(HighlightAnnotation)

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
        }
    }

    func updatedText(_ text: String) -> AnnotationSnapshot {
        guard case var .text(annotation) = self else { return self }
        annotation.text = text
        return .text(annotation)
    }

    static func makeText(at origin: CGPoint) -> AnnotationSnapshot {
        .text(
            TextAnnotation(
                color: .white,
                text: "Text",
                origin: origin
            )
        )
    }

    static func makePath(points: [CGPoint], color: AnnotationColorToken = .purple) -> AnnotationSnapshot? {
        guard points.count > 1 else { return nil }

        return .path(
            PathAnnotation(
                color: color,
                points: points
            )
        )
    }

    static func makeHighlight(points: [CGPoint]) -> AnnotationSnapshot? {
        guard points.count > 1 else { return nil }

        return .highlight(
            HighlightAnnotation(
                points: points
            )
        )
    }

    static func makeRectangle(from start: CGPoint, to end: CGPoint) -> AnnotationSnapshot? {
        let rect = CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y).standardized
        guard rect.width >= 4, rect.height >= 4 else { return nil }

        return .rect(RectAnnotation(rect: rect))
    }

    static func makeEllipse(from start: CGPoint, to end: CGPoint) -> AnnotationSnapshot? {
        let rect = CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y).standardized
        guard rect.width >= 4, rect.height >= 4 else { return nil }

        return .ellipse(EllipseAnnotation(rect: rect))
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
