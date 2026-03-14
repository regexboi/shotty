import Foundation

struct EditorDocument {
    var capturedImage: CapturedImage?
    var annotations: [AnnotationSnapshot]
    var selectedTool: AnnotationTool
    var selectedAnnotationID: UUID?

    static let placeholder = EditorDocument(
        capturedImage: nil,
        annotations: [],
        selectedTool: .pencil,
        selectedAnnotationID: nil
    )
}
