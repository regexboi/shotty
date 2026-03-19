import AppKit
import SwiftUI

struct StyledScreenshotStageView: View {
    let capturedImage: CapturedImage
    let appearance: ScreenshotAppearance
    let annotations: [AnnotationSnapshot]
    var hiddenTextAnnotationID: UUID? = nil

    private var layout: ScreenshotPresentationLayout {
        ScreenshotPresentationLayout(capturedImage: capturedImage, appearance: appearance)
    }

    private var visibleTextAnnotations: [TextAnnotation] {
        annotations.compactMap { annotation in
            guard case let .text(textAnnotation) = annotation else { return nil }
            guard textAnnotation.id != hiddenTextAnnotationID else { return nil }
            guard textAnnotation.textBounds.intersects(layout.visibleImageRect) else { return nil }
            return textAnnotation
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if appearance.backgroundModeEnabled {
                ScreenshotBackgroundView(
                    preset: appearance.backgroundPreset,
                    cornerRadius: layout.backgroundCornerRadius
                )
                .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)
            }

            screenshotCard

            ForEach(visibleTextAnnotations) { annotation in
                let textRect = layout.canvasRect(fromSourceRect: annotation.textBounds)

                Text(annotation.text)
                    .font(.system(size: annotation.fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(annotation.color.color)
                    .shadow(color: .black.opacity(0.22), radius: 1, x: 0, y: 1)
                    .frame(width: textRect.width, height: textRect.height, alignment: .topLeading)
                    .offset(x: textRect.minX, y: textRect.minY)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height, alignment: .topLeading)
    }

    private var screenshotCard: some View {
        let cornerRadius = appearance.clampedCornerRadius
        let shadowAmount = appearance.backgroundModeEnabled ? appearance.clampedShadow : 0
        let shadowOpacity = min(0.34, 0.12 + (shadowAmount / 120))
        let shadowOffset = max(2, shadowAmount * 0.55)
        let visibleOrigin = CGPoint(x: layout.visibleImageRect.minX, y: layout.visibleImageRect.minY)

        return ZStack(alignment: .topLeading) {
            if shadowAmount > 0 {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.16))
                    .frame(width: layout.imageFrame.width, height: layout.imageFrame.height)
                    .shadow(color: .black.opacity(shadowOpacity), radius: shadowAmount * 1.9, x: 0, y: shadowOffset)
                    .shadow(color: ShottyTheme.purple.opacity(0.12), radius: shadowAmount * 1.1, x: 0, y: max(1, shadowAmount * 0.24))
            }

            ZStack(alignment: .topLeading) {
                Image(nsImage: capturedImage.image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: layout.sourceImageSize.width, height: layout.sourceImageSize.height)
                    .offset(x: -visibleOrigin.x, y: -visibleOrigin.y)

                ScreenshotAnnotationLayer(annotations: annotations)
                    .frame(width: layout.sourceImageSize.width, height: layout.sourceImageSize.height)
                    .offset(x: -visibleOrigin.x, y: -visibleOrigin.y)
                    .allowsHitTesting(false)
            }
            .frame(width: layout.imageFrame.width, height: layout.imageFrame.height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
        .offset(x: layout.imageFrame.minX, y: layout.imageFrame.minY)
    }
}

private struct ScreenshotAnnotationLayer: View {
    let annotations: [AnnotationSnapshot]

    var body: some View {
        Canvas { context, _ in
            for annotation in annotations {
                draw(annotation, in: &context)
            }
        }
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
        case let .arrow(arrowAnnotation):
            context.stroke(
                Path(arrowPath(from: arrowAnnotation.start, to: arrowAnnotation.end, lineWidth: arrowAnnotation.lineWidth)),
                with: .color(arrowAnnotation.color.color),
                style: StrokeStyle(
                    lineWidth: arrowAnnotation.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
    }
}
