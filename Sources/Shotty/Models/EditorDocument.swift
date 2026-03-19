import Foundation

struct EditorDocument {
    var capturedImage: CapturedImage?
    var annotations: [AnnotationSnapshot]
    var appearance: ScreenshotAppearance
    var selectedTool: AnnotationTool
    var selectedAnnotationID: UUID?

    static let placeholder = EditorDocument(
        capturedImage: nil,
        annotations: [],
        appearance: ScreenshotAppearance(),
        selectedTool: .pencil,
        selectedAnnotationID: nil
    )
}
