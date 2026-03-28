import AppKit
import Foundation
import SwiftUI
import Vision

enum ScreenshotBalanceAnalyzer {
    static func focusRect(for image: NSImage) -> CGRect? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        return focusRect(for: cgImage, logicalSize: image.size)
    }

    private static func focusRect(for cgImage: CGImage, logicalSize: CGSize) -> CGRect? {
        attentionFocusRect(for: cgImage, logicalSize: logicalSize)
            ?? objectnessFocusRect(for: cgImage, logicalSize: logicalSize)
    }

    private static func attentionFocusRect(for cgImage: CGImage, logicalSize: CGSize) -> CGRect? {
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        return perform(request: request, on: cgImage, logicalSize: logicalSize)
    }

    private static func objectnessFocusRect(for cgImage: CGImage, logicalSize: CGSize) -> CGRect? {
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        return perform(request: request, on: cgImage, logicalSize: logicalSize)
    }

    private static func perform(
        request: VNImageBasedRequest,
        on cgImage: CGImage,
        logicalSize: CGSize
    ) -> CGRect? {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard
            let observation = (request.results?.first as? VNSaliencyImageObservation),
            let salientObjects = observation.salientObjects,
            salientObjects.isEmpty == false
        else {
            return nil
        }

        let focusRect = salientObjects
            .map { rect(from: $0.boundingBox, in: logicalSize) }
            .reduce(CGRect.null) { partialResult, rect in
                partialResult.union(rect)
            }

        guard focusRect.isNull == false, focusRect.isEmpty == false else {
            return nil
        }

        let margin = min(logicalSize.width, logicalSize.height) * 0.04
        let fullRect = CGRect(origin: .zero, size: logicalSize)
        return focusRect.insetBy(dx: -margin, dy: -margin).intersection(fullRect)
    }

    private static func rect(from normalizedRect: CGRect, in logicalSize: CGSize) -> CGRect {
        CGRect(
            x: normalizedRect.minX * logicalSize.width,
            y: (1 - normalizedRect.maxY) * logicalSize.height,
            width: normalizedRect.width * logicalSize.width,
            height: normalizedRect.height * logicalSize.height
        )
    }
}

struct ScreenshotPresentationLayout {
    let sourceImageSize: CGSize
    let visibleImageRect: CGRect
    let canvasSize: CGSize
    let imageFrame: CGRect
    let backgroundCornerRadius: CGFloat
    let appearance: ScreenshotAppearance

    init(capturedImage: CapturedImage, appearance: ScreenshotAppearance) {
        let pixelScale = pixelScale(for: capturedImage)
        sourceImageSize = alignedSize(capturedImage.image.size, scale: pixelScale)
        self.appearance = appearance

        let fullRect = CGRect(origin: .zero, size: sourceImageSize)
        let maxInset = max(0, (min(sourceImageSize.width, sourceImageSize.height) - 1) / 2)
        let inset = alignedValue(min(appearance.clampedInset, maxInset), scale: pixelScale)
        let insetRect = fullRect.insetBy(dx: inset, dy: inset)
        visibleImageRect = insetRect.isEmpty ? fullRect : alignedRect(insetRect, scale: pixelScale)

        if appearance.backgroundModeEnabled {
            let padding = alignedValue(appearance.clampedPadding, scale: pixelScale)
            let visibleSize = visibleImageRect.size
            canvasSize = CGSize(
                width: visibleSize.width + (padding * 2),
                height: visibleSize.height + (padding * 2)
            )

            var imageOrigin = CGPoint(x: padding, y: padding)

            if appearance.balanceEnabled,
               let focusRect = capturedImage.balanceFocusRect?.intersection(visibleImageRect),
               focusRect.isNull == false,
               focusRect.isEmpty == false {
                let visibleFocusRect = focusRect.offsetBy(dx: -visibleImageRect.minX, dy: -visibleImageRect.minY)
                let deltaX = ((visibleSize.width / 2) - visibleFocusRect.midX) * 0.82
                let deltaY = ((visibleSize.height / 2) - visibleFocusRect.midY) * 0.82

                imageOrigin.x = alignedValue(
                    clamp(imageOrigin.x + deltaX, min: 0, max: canvasSize.width - visibleSize.width),
                    scale: pixelScale
                )
                imageOrigin.y = alignedValue(
                    clamp(imageOrigin.y + deltaY, min: 0, max: canvasSize.height - visibleSize.height),
                    scale: pixelScale
                )
            }

            imageFrame = alignedRect(CGRect(origin: imageOrigin, size: visibleSize), scale: pixelScale)
            backgroundCornerRadius = alignedValue(appearance.clampedBackgroundCornerRadius, scale: pixelScale)
        } else {
            canvasSize = visibleImageRect.size
            imageFrame = CGRect(origin: .zero, size: visibleImageRect.size)
            backgroundCornerRadius = 0
        }
    }

    func sourcePoint(fromCanvasPoint point: CGPoint) -> CGPoint? {
        guard imageFrame.contains(point) else { return nil }

        return CGPoint(
            x: visibleImageRect.minX + (point.x - imageFrame.minX),
            y: visibleImageRect.minY + (point.y - imageFrame.minY)
        )
    }

    func canvasRect(fromSourceRect rect: CGRect) -> CGRect {
        CGRect(
            x: imageFrame.minX + (rect.minX - visibleImageRect.minX),
            y: imageFrame.minY + (rect.minY - visibleImageRect.minY),
            width: rect.width,
            height: rect.height
        )
    }
}

enum ScreenshotRenderer {
    enum RenderError: Error {
        case missingImage
        case renderFailed
    }

    @MainActor
    static func renderedImage(for document: EditorDocument) throws -> NSImage {
        guard let capturedImage = document.capturedImage else {
            throw RenderError.missingImage
        }

        let layout = ScreenshotPresentationLayout(
            capturedImage: capturedImage,
            appearance: document.appearance
        )
        let renderer = ImageRenderer(
            content: StyledScreenshotStageView(
                capturedImage: capturedImage,
                appearance: document.appearance,
                annotations: document.annotations
            )
        )
        renderer.proposedSize = ProposedViewSize(layout.canvasSize)
        renderer.scale = exportScale(for: capturedImage)

        guard let image = renderer.nsImage else {
            throw RenderError.renderFailed
        }

        return image
    }

    private static func exportScale(for capturedImage: CapturedImage) -> CGFloat {
        pixelScale(for: capturedImage)
    }
}

private func clamp(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
    Swift.max(minimum, Swift.min(maximum, value))
}

private func pixelScale(for capturedImage: CapturedImage) -> CGFloat {
    if let cgImage = capturedImage.image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        let widthScale = CGFloat(cgImage.width) / max(capturedImage.image.size.width, 1)
        let heightScale = CGFloat(cgImage.height) / max(capturedImage.image.size.height, 1)
        return max(widthScale, heightScale, capturedImage.displayScale, 1)
    }

    return max(capturedImage.displayScale, 1)
}

private func alignedValue(_ value: CGFloat, scale: CGFloat) -> CGFloat {
    guard scale > 0 else { return value }
    return (value * scale).rounded() / scale
}

private func alignedSize(_ size: CGSize, scale: CGFloat) -> CGSize {
    CGSize(
        width: alignedValue(size.width, scale: scale),
        height: alignedValue(size.height, scale: scale)
    )
}

private func alignedRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
    CGRect(
        x: alignedValue(rect.origin.x, scale: scale),
        y: alignedValue(rect.origin.y, scale: scale),
        width: alignedValue(rect.size.width, scale: scale),
        height: alignedValue(rect.size.height, scale: scale)
    )
}
