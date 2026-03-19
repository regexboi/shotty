import AppKit
import SwiftUI

struct AnnotationCanvasView: View {
    @ObservedObject var viewModel: EditorViewModel

    @State private var gestureSession: GestureSession?
    @State private var draftAnnotation: DraftAnnotation?
    @State private var editingText = ""
    @State private var textEditorSessionID = UUID()

    var body: some View {
        GeometryReader { proxy in
            let containerSize = proxy.size

            ZStack {
                if let capturedImage = viewModel.document.capturedImage {
                    let presentation = ScreenshotPresentationLayout(
                        capturedImage: capturedImage,
                        appearance: viewModel.document.appearance
                    )
                    let layout = CanvasLayout(
                        containerSize: containerSize,
                        presentation: presentation
                    )

                    canvasContent(
                        capturedImage: capturedImage,
                        layout: layout
                    )
                    .gesture(canvasGesture(layout: layout))
                } else {
                    placeholderContent
                }
            }
        }
        .onChange(of: viewModel.textEditingAnnotationID) { _, newValue in
            syncTextEditor(with: newValue)
        }
    }

    private var placeholderContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "viewfinder.circle")
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ShottyTheme.goldBright,
                            ShottyTheme.pinkBright.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: ShottyTheme.gold.opacity(0.22), radius: 18, x: 0, y: 8)

            Text("Capture preview lands here")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(ShottyTheme.goldBright)

            Text("Launch the app, hit the global hotkey, and the selected screenshot will appear here.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(ShottyTheme.blueBright.opacity(0.90))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(32)
    }

    @ViewBuilder
    private func canvasContent(
        capturedImage: CapturedImage,
        layout: CanvasLayout
    ) -> some View {
        ZStack(alignment: .topLeading) {
            StyledScreenshotStageView(
                capturedImage: capturedImage,
                appearance: viewModel.document.appearance,
                annotations: stageAnnotations,
                hiddenTextAnnotationID: viewModel.textEditingAnnotationID
            )
            .scaleEffect(layout.scale, anchor: .topLeading)
            .frame(width: layout.canvasRect.width, height: layout.canvasRect.height, alignment: .topLeading)
            .offset(x: layout.canvasRect.minX, y: layout.canvasRect.minY)

            ForEach(editableTextAnnotations) { annotation in
                editingTextOverlay(for: annotation, layout: layout)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func editingTextOverlay(
        for annotation: TextAnnotation,
        layout: CanvasLayout
    ) -> some View {
        if viewModel.textEditingAnnotationID == annotation.id,
           annotation.textBounds.intersects(layout.presentation.visibleImageRect) {
            let textRect = layout.viewRect(fromSourceRect: annotation.textBounds)
            let editorWidth = max(textRect.width, 120 * layout.scale)
            let editorHeight = max(textRect.height, annotation.fontSize * layout.scale * 1.2)

            InlineAnnotationTextField(
                text: $editingText,
                fontSize: annotation.fontSize * layout.scale,
                color: annotation.color.nsColor,
                onCommit: commitInlineTextEdit,
                onCancel: cancelInlineTextEdit
            )
            .id(textEditorSessionID)
            .frame(width: editorWidth, height: editorHeight, alignment: .topLeading)
            .offset(x: textRect.minX, y: textRect.minY)
        }
    }

    private var editableTextAnnotations: [TextAnnotation] {
        stageAnnotations.compactMap { annotation in
            guard case let .text(textAnnotation) = annotation else { return nil }
            return textAnnotation
        }
    }

    private var stageAnnotations: [AnnotationSnapshot] {
        if let draftSnapshot = draftAnnotation?.snapshot {
            return viewModel.document.annotations + [draftSnapshot]
        }

        return viewModel.document.annotations
    }

    private func canvasGesture(layout: CanvasLayout) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                handleGestureChanged(value, layout: layout)
            }
            .onEnded { value in
                handleGestureEnded(value, layout: layout)
            }
    }

    private func handleGestureChanged(_ value: DragGesture.Value, layout: CanvasLayout) {
        guard let startImagePoint = layout.imagePoint(from: value.startLocation) else {
            gestureSession = nil
            draftAnnotation = nil
            return
        }

        if gestureSession == nil {
            if viewModel.isTextEditing {
                commitInlineTextEdit()
            }

            gestureSession = GestureSession(
                startViewPoint: value.startLocation,
                startImagePoint: startImagePoint
            )
        }

        guard let session = gestureSession else { return }
        let distance = hypot(
            value.location.x - session.startViewPoint.x,
            value.location.y - session.startViewPoint.y
        )

        guard distance > 4, let currentPoint = layout.imagePoint(from: value.location) else { return }
        updateDraftAnnotation(start: session.startImagePoint, current: currentPoint)
    }

    private func handleGestureEnded(_ value: DragGesture.Value, layout: CanvasLayout) {
        defer {
            gestureSession = nil
            draftAnnotation = nil
        }

        guard let session = gestureSession else { return }

        let distance = hypot(
            value.location.x - session.startViewPoint.x,
            value.location.y - session.startViewPoint.y
        )

        guard layout.imagePoint(from: value.location) != nil else {
            return
        }

        if distance <= 4 {
            handleTap(at: session.startImagePoint, layout: layout)
            return
        }

        guard let snapshot = draftAnnotation?.snapshot else { return }
        viewModel.addAnnotation(snapshot)
    }

    private func handleTap(at point: CGPoint, layout: CanvasLayout) {
        if let hitID = hitTestAnnotation(at: point) {
            viewModel.selectAnnotation(hitID)

            if viewModel.document.selectedTool == .text,
               let annotation = viewModel.annotation(withID: hitID),
               annotation.tool == .text {
                beginInlineTextEdit(annotationID: hitID)
            }

            return
        }

        viewModel.selectAnnotation(nil)

        guard viewModel.document.selectedTool == .text else { return }
        let origin = clampedTextOrigin(point, imageBounds: layout.presentation.visibleImageRect)
        let annotationID = viewModel.createTextAnnotation(at: origin)
        beginInlineTextEdit(annotationID: annotationID)
    }

    private func updateDraftAnnotation(start: CGPoint, current: CGPoint) {
        switch viewModel.document.selectedTool {
        case .text:
            return
        case .pencil, .highlight:
            let style = viewModel.currentToolStyle
            if draftAnnotation == nil {
                draftAnnotation = .stroke(
                    tool: viewModel.document.selectedTool,
                    color: style.colorToken,
                    lineWidth: style.sizePreset.lineWidth(for: viewModel.document.selectedTool),
                    points: [start, current]
                )
                return
            }

            draftAnnotation?.append(point: current)
        case .rectangle, .circle, .arrow:
            let style = viewModel.currentToolStyle
            draftAnnotation = .shape(
                tool: viewModel.document.selectedTool,
                color: style.colorToken,
                lineWidth: style.sizePreset.lineWidth(for: viewModel.document.selectedTool),
                start: start,
                current: current
            )
        }
    }

    private func hitTestAnnotation(at point: CGPoint) -> UUID? {
        for annotation in viewModel.document.annotations.reversed() where annotation.hitTest(point) {
            return annotation.id
        }

        return nil
    }

    private func beginInlineTextEdit(annotationID: UUID) {
        guard let annotation = viewModel.annotation(withID: annotationID), let textValue = annotation.textValue else {
            return
        }

        editingText = textValue
        textEditorSessionID = UUID()
        viewModel.beginTextEditing(annotationID: annotationID)
    }

    private func commitInlineTextEdit() {
        guard let annotationID = viewModel.textEditingAnnotationID else { return }
        let textValue = editingText
        editingText = ""
        viewModel.commitTextEdit(annotationID: annotationID, text: textValue)
    }

    private func cancelInlineTextEdit() {
        editingText = ""
        viewModel.cancelTextEditing()
    }

    private func syncTextEditor(with annotationID: UUID?) {
        guard let annotationID, let textValue = viewModel.annotation(withID: annotationID)?.textValue else {
            editingText = ""
            return
        }

        if editingText != textValue {
            editingText = textValue
        }
    }

    private func clampedTextOrigin(_ point: CGPoint, imageBounds: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, imageBounds.minX + 12), max(imageBounds.maxX - 80, imageBounds.minX + 12)),
            y: min(max(point.y, imageBounds.minY + 12), max(imageBounds.maxY - 38, imageBounds.minY + 12))
        )
    }

}

private struct CanvasLayout {
    let presentation: ScreenshotPresentationLayout
    let imageSize: CGSize
    let canvasRect: CGRect
    let scale: CGFloat

    init(containerSize: CGSize, presentation: ScreenshotPresentationLayout) {
        self.presentation = presentation
        imageSize = presentation.sourceImageSize

        let widthScale = max((containerSize.width - 32) / max(presentation.canvasSize.width, 1), 0.01)
        let heightScale = max((containerSize.height - 32) / max(presentation.canvasSize.height, 1), 0.01)
        scale = min(widthScale, heightScale)

        let fittedSize = CGSize(
            width: presentation.canvasSize.width * scale,
            height: presentation.canvasSize.height * scale
        )
        let origin = CGPoint(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2
        )
        canvasRect = CGRect(origin: origin, size: fittedSize)
    }

    func imagePoint(from viewPoint: CGPoint) -> CGPoint? {
        let canvasPoint = CGPoint(
            x: (viewPoint.x - canvasRect.minX) / scale,
            y: (viewPoint.y - canvasRect.minY) / scale
        )

        return presentation.sourcePoint(fromCanvasPoint: canvasPoint)
    }

    func viewRect(fromSourceRect imageRect: CGRect) -> CGRect {
        let canvasRect = presentation.canvasRect(fromSourceRect: imageRect)

        return CGRect(
            x: self.canvasRect.minX + (canvasRect.minX * scale),
            y: self.canvasRect.minY + (canvasRect.minY * scale),
            width: canvasRect.width * scale,
            height: canvasRect.height * scale
        )
    }
}

private struct GestureSession {
    let startViewPoint: CGPoint
    let startImagePoint: CGPoint
}

private enum DraftAnnotation {
    case stroke(tool: AnnotationTool, color: AnnotationColorToken, lineWidth: CGFloat, points: [CGPoint])
    case shape(tool: AnnotationTool, color: AnnotationColorToken, lineWidth: CGFloat, start: CGPoint, current: CGPoint)

    var snapshot: AnnotationSnapshot? {
        switch self {
        case let .stroke(tool, color, lineWidth, points):
            switch tool {
            case .pencil:
                return AnnotationSnapshot.makePath(points: points, color: color, lineWidth: lineWidth)
            case .highlight:
                return AnnotationSnapshot.makeHighlight(points: points, color: color, lineWidth: lineWidth)
            default:
                return nil
            }
        case let .shape(tool, color, lineWidth, start, current):
            switch tool {
            case .rectangle:
                return AnnotationSnapshot.makeRectangle(from: start, to: current, color: color, lineWidth: lineWidth)
            case .circle:
                return AnnotationSnapshot.makeEllipse(from: start, to: current, color: color, lineWidth: lineWidth)
            case .arrow:
                return AnnotationSnapshot.makeArrow(from: start, to: current, color: color, lineWidth: lineWidth)
            default:
                return nil
            }
        }
    }

    mutating func append(point: CGPoint) {
        guard case let .stroke(tool, color, lineWidth, existingPoints) = self else { return }
        var points = existingPoints

        if let lastPoint = points.last,
           hypot(point.x - lastPoint.x, point.y - lastPoint.y) < 1.25 {
            return
        }

        points.append(point)
        self = .stroke(tool: tool, color: color, lineWidth: lineWidth, points: points)
    }
}

private struct InlineAnnotationTextField: NSViewRepresentable {
    @Binding var text: String

    let fontSize: CGFloat
    let color: NSColor
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: text)
        textField.isBordered = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.isBezeled = false
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byClipping
        textField.maximumNumberOfLines = 1
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: fontSize, weight: .semibold)
        textField.textColor = color
        textField.alignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        nsView.font = .systemFont(ofSize: fontSize, weight: .semibold)
        nsView.textColor = color

        if context.coordinator.didFocus == false {
            context.coordinator.didFocus = true
            DispatchQueue.main.async {
                guard let window = nsView.window else { return }
                window.makeFirstResponder(nsView)
                nsView.currentEditor()?.selectAll(nil)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: InlineAnnotationTextField
        var didFocus = false
        private var didFinish = false

        init(parent: InlineAnnotationTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                Task { @MainActor in
                    self.finish(commit: true)
                }
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                Task { @MainActor in
                    self.finish(commit: false)
                }
                return true
            default:
                return false
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            Task { @MainActor in
                self.finish(commit: true)
            }
        }

        @MainActor
        private func finish(commit: Bool) {
            guard didFinish == false else { return }
            didFinish = true

            if commit {
                parent.onCommit()
            } else {
                parent.onCancel()
            }
        }
    }
}
