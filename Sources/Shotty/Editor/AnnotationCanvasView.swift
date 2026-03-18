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
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ShottyTheme.canvasBaseTop,
                                ShottyTheme.canvasBaseBottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)

                if let capturedImage = viewModel.document.capturedImage {
                    let layout = CanvasLayout(
                        containerSize: containerSize,
                        imageSize: capturedImage.image.size
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
                .foregroundStyle(ShottyTheme.goldBright.opacity(0.9))

            Text("Capture preview lands here")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))

            Text("Launch the app, hit the global hotkey, and the selected screenshot will appear here.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(32)
    }

    @ViewBuilder
    private func canvasContent(
        capturedImage: CapturedImage,
        layout: CanvasLayout
    ) -> some View {
        ZStack(alignment: .topLeading) {
            Image(nsImage: capturedImage.image)
                .resizable()
                .interpolation(.high)
                .frame(width: layout.imageRect.width, height: layout.imageRect.height)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .position(x: layout.imageRect.midX, y: layout.imageRect.midY)

            annotationDrawingLayer(layout: layout)
                .frame(width: layout.imageRect.width, height: layout.imageRect.height)
                .position(x: layout.imageRect.midX, y: layout.imageRect.midY)
                .allowsHitTesting(false)

            ForEach(textAnnotations) { annotation in
                textOverlay(for: annotation, layout: layout)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .contentShape(Rectangle())
    }

    private func annotationDrawingLayer(layout: CanvasLayout) -> some View {
        Canvas { context, size in
            context.scaleBy(x: layout.scale, y: layout.scale)

            for annotation in viewModel.document.annotations {
                draw(annotation, in: &context)
            }

            if let draftSnapshot = draftAnnotation?.snapshot {
                draw(draftSnapshot, in: &context)
            }

            if let selectedAnnotation = viewModel.selectedAnnotation {
                drawSelection(for: selectedAnnotation, in: &context, scale: layout.scale)
            }
        }
    }

    @ViewBuilder
    private func textOverlay(
        for annotation: TextAnnotation,
        layout: CanvasLayout
    ) -> some View {
        let textRect = layout.viewRect(from: annotation.textBounds)
        let editorWidth = max(textRect.width + (28 * layout.scale), 180 * layout.scale)
        let editorHeight = max(textRect.height + (14 * layout.scale), 40 * layout.scale)

        if viewModel.textEditingAnnotationID == annotation.id {
            InlineAnnotationTextField(
                text: $editingText,
                fontSize: annotation.fontSize * layout.scale,
                color: annotation.color.nsColor,
                onCommit: commitInlineTextEdit,
                onCancel: cancelInlineTextEdit
            )
            .id(textEditorSessionID)
            .frame(width: editorWidth, height: editorHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            )
            .offset(x: textRect.minX - (10 * layout.scale), y: textRect.minY - (6 * layout.scale))
        } else {
            Text(annotation.text)
                .font(.system(size: annotation.fontSize * layout.scale, weight: .semibold, design: .rounded))
                .foregroundStyle(annotation.color.color)
                .shadow(color: .black.opacity(0.22), radius: 1, x: 0, y: 1)
                .frame(width: textRect.width, height: textRect.height, alignment: .topLeading)
                .offset(x: textRect.minX, y: textRect.minY)
                .allowsHitTesting(false)
        }
    }

    private var textAnnotations: [TextAnnotation] {
        viewModel.document.annotations.compactMap { annotation in
            guard case let .text(textAnnotation) = annotation else { return nil }
            return textAnnotation
        }
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
            handleTap(at: session.startImagePoint, imageSize: layout.imageSize)
            return
        }

        guard let snapshot = draftAnnotation?.snapshot else { return }
        viewModel.addAnnotation(snapshot)
    }

    private func handleTap(at point: CGPoint, imageSize: CGSize) {
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
        let origin = clampedTextOrigin(point, imageSize: imageSize)
        let annotationID = viewModel.createTextAnnotation(at: origin)
        beginInlineTextEdit(annotationID: annotationID)
    }

    private func updateDraftAnnotation(start: CGPoint, current: CGPoint) {
        switch viewModel.document.selectedTool {
        case .text:
            return
        case .pencil, .highlight:
            if draftAnnotation == nil {
                draftAnnotation = .stroke(
                    tool: viewModel.document.selectedTool,
                    points: [start, current]
                )
                return
            }

            draftAnnotation?.append(point: current)
        case .rectangle, .circle:
            draftAnnotation = .shape(
                tool: viewModel.document.selectedTool,
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

    private func clampedTextOrigin(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 12), max(imageSize.width - 80, 12)),
            y: min(max(point.y, 12), max(imageSize.height - 38, 12))
        )
    }

    private func draw(_ annotation: AnnotationSnapshot, in context: inout GraphicsContext) {
        switch annotation {
        case .text:
            break
        case let .path(pathAnnotation):
            context.stroke(
                Path(smoothedPath(for: pathAnnotation.points)),
                with: .color(pathAnnotation.color.color),
                style: StrokeStyle(
                    lineWidth: pathAnnotation.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        case let .rect(rectAnnotation):
            context.stroke(
                Path(rectAnnotation.rect.standardized),
                with: .color(rectAnnotation.color.color),
                style: StrokeStyle(
                    lineWidth: rectAnnotation.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        case let .ellipse(ellipseAnnotation):
            context.stroke(
                Path(ellipseIn: ellipseAnnotation.rect.standardized),
                with: .color(ellipseAnnotation.color.color),
                style: StrokeStyle(
                    lineWidth: ellipseAnnotation.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        case let .highlight(highlightAnnotation):
            context.blendMode = .multiply
            context.stroke(
                Path(smoothedPath(for: highlightAnnotation.points)),
                with: .color(highlightAnnotation.color.color.opacity(0.34)),
                style: StrokeStyle(
                    lineWidth: highlightAnnotation.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            context.blendMode = .normal
        }
    }

    private func drawSelection(
        for annotation: AnnotationSnapshot,
        in context: inout GraphicsContext,
        scale: CGFloat
    ) {
        let selectionRect = annotation.selectionBounds
        let lineWidth = max(2 / max(scale, 0.01), 0.75)
        let dashPattern = [10 / max(scale, 0.01), 6 / max(scale, 0.01)]
        let selectionPath: Path

        switch annotation {
        case .ellipse:
            selectionPath = Path(ellipseIn: selectionRect)
        default:
            selectionPath = Path(selectionRect)
        }

        context.fill(
            selectionPath,
            with: .color(.white.opacity(0.05))
        )
        context.stroke(
            selectionPath,
            with: .color(.white.opacity(0.92)),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: dashPattern
            )
        )
    }
}

private struct CanvasLayout {
    let imageSize: CGSize
    let imageRect: CGRect
    let scale: CGFloat

    init(containerSize: CGSize, imageSize: CGSize) {
        self.imageSize = imageSize

        let widthScale = max((containerSize.width - 32) / max(imageSize.width, 1), 0.01)
        let heightScale = max((containerSize.height - 32) / max(imageSize.height, 1), 0.01)
        scale = min(widthScale, heightScale)

        let fittedSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        let origin = CGPoint(
            x: (containerSize.width - fittedSize.width) / 2,
            y: (containerSize.height - fittedSize.height) / 2
        )
        imageRect = CGRect(origin: origin, size: fittedSize)
    }

    func imagePoint(from viewPoint: CGPoint) -> CGPoint? {
        guard imageRect.contains(viewPoint) else { return nil }

        return CGPoint(
            x: (viewPoint.x - imageRect.minX) / scale,
            y: (viewPoint.y - imageRect.minY) / scale
        )
    }

    func viewRect(from imageRect: CGRect) -> CGRect {
        CGRect(
            x: self.imageRect.minX + (imageRect.minX * scale),
            y: self.imageRect.minY + (imageRect.minY * scale),
            width: imageRect.width * scale,
            height: imageRect.height * scale
        )
    }
}

private struct GestureSession {
    let startViewPoint: CGPoint
    let startImagePoint: CGPoint
}

private enum DraftAnnotation {
    case stroke(tool: AnnotationTool, points: [CGPoint])
    case shape(tool: AnnotationTool, start: CGPoint, current: CGPoint)

    var snapshot: AnnotationSnapshot? {
        switch self {
        case let .stroke(tool, points):
            switch tool {
            case .pencil:
                return AnnotationSnapshot.makePath(points: points)
            case .highlight:
                return AnnotationSnapshot.makeHighlight(points: points)
            default:
                return nil
            }
        case let .shape(tool, start, current):
            switch tool {
            case .rectangle:
                return AnnotationSnapshot.makeRectangle(from: start, to: current)
            case .circle:
                return AnnotationSnapshot.makeEllipse(from: start, to: current)
            default:
                return nil
            }
        }
    }

    mutating func append(point: CGPoint) {
        guard case let .stroke(tool, existingPoints) = self else { return }
        var points = existingPoints

        if let lastPoint = points.last,
           hypot(point.x - lastPoint.x, point.y - lastPoint.y) < 1.25 {
            return
        }

        points.append(point)
        self = .stroke(tool: tool, points: points)
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
