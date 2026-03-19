import AppKit
import Foundation

@MainActor
final class ExportService {
    func copyCurrentImage(document: EditorDocument) -> Bool {
        guard let image = renderedImage(for: document) else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    func showSavePanel(for document: EditorDocument, from window: NSWindow?) -> Bool {
        guard let image = renderedImage(for: document) else { return false }
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return false
        }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Shotty Capture.png"

        if let window {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                try? pngData.write(to: url)
            }
        } else {
            guard panel.runModal() == .OK, let url = panel.url else { return true }
            try? pngData.write(to: url)
        }

        return true
    }

    private func renderedImage(for document: EditorDocument) -> NSImage? {
        guard let capturedImage = document.capturedImage else { return nil }

        let logicalSize = capturedImage.image.size
        let pixelSize = pixelSize(for: capturedImage)

        guard
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelSize.width,
                pixelsHigh: pixelSize.height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ),
            let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            return nil
        }

        bitmap.size = logicalSize
        bitmapContext.cgContext.clear(CGRect(x: 0, y: 0, width: pixelSize.width, height: pixelSize.height))

        let graphicsContext = NSGraphicsContext(cgContext: bitmapContext.cgContext, flipped: true)
        graphicsContext.cgContext.interpolationQuality = .high
        graphicsContext.cgContext.setShouldAntialias(true)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        let imageRect = CGRect(origin: .zero, size: logicalSize)
        capturedImage.image.draw(in: imageRect, from: .zero, operation: .copy, fraction: 1)

        for annotation in document.annotations {
            draw(annotation, in: graphicsContext.cgContext)
        }

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: logicalSize)
        image.addRepresentation(bitmap)
        return image
    }

    private func pixelSize(for capturedImage: CapturedImage) -> (width: Int, height: Int) {
        if let cgImage = capturedImage.image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return (width: cgImage.width, height: cgImage.height)
        }

        let width = max(1, Int((capturedImage.image.size.width * capturedImage.displayScale).rounded(.up)))
        let height = max(1, Int((capturedImage.image.size.height * capturedImage.displayScale).rounded(.up)))
        return (width: width, height: height)
    }

    private func draw(_ annotation: AnnotationSnapshot, in context: CGContext) {
        switch annotation {
        case let .text(textAnnotation):
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: textAnnotation.fontSize, weight: .semibold),
                .foregroundColor: textAnnotation.color.nsColor
            ]
            (textAnnotation.text as NSString).draw(at: textAnnotation.origin, withAttributes: attributes)
        case let .path(pathAnnotation):
            stroke(
                points: pathAnnotation.points,
                lineWidth: pathAnnotation.lineWidth,
                color: pathAnnotation.color.nsColor,
                alpha: 1,
                blendMode: .normal,
                in: context
            )
        case let .rect(rectAnnotation):
            let path = NSBezierPath(rect: rectAnnotation.rect.standardized)
            path.lineWidth = rectAnnotation.lineWidth
            rectAnnotation.color.nsColor.setStroke()
            path.stroke()
        case let .ellipse(ellipseAnnotation):
            let path = NSBezierPath(ovalIn: ellipseAnnotation.rect.standardized)
            path.lineWidth = ellipseAnnotation.lineWidth
            ellipseAnnotation.color.nsColor.setStroke()
            path.stroke()
        case let .highlight(highlightAnnotation):
            stroke(
                points: highlightAnnotation.points,
                lineWidth: highlightAnnotation.lineWidth,
                color: highlightAnnotation.color.nsColor,
                alpha: 0.34,
                blendMode: .multiply,
                in: context
            )
        }
    }

    private func stroke(
        points: [CGPoint],
        lineWidth: CGFloat,
        color: NSColor,
        alpha: CGFloat,
        blendMode: CGBlendMode,
        in context: CGContext
    ) {
        guard points.count > 1 else { return }
        let path = NSBezierPath(cgPath: smoothedPath(for: points))

        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        context.saveGState()
        context.setBlendMode(blendMode)
        color.withAlphaComponent(alpha).setStroke()
        path.stroke()
        context.restoreGState()
    }
}
