import CoreGraphics
import Foundation

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
            return "Click to place copy"
        case .pencil:
            return "Freehand paths"
        case .rectangle:
            return "Stroke-only box"
        case .circle:
            return "Stroke-only ellipse"
        case .highlight:
            return "Semi-transparent emphasis"
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
}

enum AnnotationColorToken: String, Codable, CaseIterable {
    case purple
    case gold
    case white
}

protocol Annotation: Identifiable {
    var id: UUID { get }
    var color: AnnotationColorToken { get set }
}

struct TextAnnotation: Annotation {
    let id = UUID()
    var color: AnnotationColorToken = .white
    var text: String
    var origin: CGPoint
    var fontSize: CGFloat
}

struct PathAnnotation: Annotation {
    let id = UUID()
    var color: AnnotationColorToken = .purple
    var points: [CGPoint]
    var lineWidth: CGFloat
}

struct RectAnnotation: Annotation {
    let id = UUID()
    var color: AnnotationColorToken = .purple
    var rect: CGRect
    var lineWidth: CGFloat
}

struct EllipseAnnotation: Annotation {
    let id = UUID()
    var color: AnnotationColorToken = .gold
    var rect: CGRect
    var lineWidth: CGFloat
}

struct HighlightAnnotation: Annotation {
    let id = UUID()
    var color: AnnotationColorToken = .gold
    var points: [CGPoint]
    var lineWidth: CGFloat
}

enum AnnotationSnapshot: Identifiable {
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
}
