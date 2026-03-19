import AppKit
import CoreGraphics
import Foundation
@preconcurrency import ScreenCaptureKit

@MainActor
final class ScreenshotService {
    enum CaptureError: LocalizedError {
        case selectionMissingDisplay
        case missingDisplayMetadata
        case captureUnavailable
        case imageConstructionFailed

        var errorDescription: String? {
            switch self {
            case .selectionMissingDisplay:
                return "The selected region did not intersect any active display."
            case .missingDisplayMetadata:
                return "Shotty could not resolve the selected display for capture."
            case .captureUnavailable:
                return "ScreenCaptureKit returned an empty screenshot."
            case .imageConstructionFailed:
                return "Shotty could not build an image from the captured pixels."
            }
        }
    }

    func captureSelection(in rect: CGRect) async throws -> CapturedImage {
        let selection = rect.standardized.integral
        let intersectingScreens = NSScreen.screens.filter { $0.frame.intersects(selection) }

        guard intersectingScreens.isEmpty == false else {
            throw CaptureError.selectionMissingDisplay
        }

        let image = try await captureImageByCompositingDisplays(in: selection, screens: intersectingScreens)

        let preferredScale = maximumScale(for: intersectingScreens)
        let nsImage = NSImage(cgImage: image, size: NSSize(width: selection.width, height: selection.height))

        return CapturedImage(
            image: nsImage,
            captureRect: selection,
            displayScale: preferredScale
        )
    }

    func hasCaptureAccess() async -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        do {
            _ = try await currentShareableContent()
            return true
        } catch {
            return false
        }
    }

    func looksLikePermissionFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        let description = "\(nsError.domain) \(nsError.localizedDescription)".lowercased()

        return description.contains("permission")
            || description.contains("screen recording")
            || description.contains("not authorized")
            || description.contains("not permitted")
            || description.contains("access denied")
    }

    private func captureImageByCompositingDisplays(
        in rect: CGRect,
        screens: [NSScreen]
    ) async throws -> CGImage {
        let shareableContent = try await currentShareableContent()
        let displaysByID = Dictionary(uniqueKeysWithValues: shareableContent.displays.map { ($0.displayID, $0) })

        let orderedSegments = screens
            .sorted { lhs, rhs in
                if lhs.frame.minY == rhs.frame.minY {
                    return lhs.frame.minX < rhs.frame.minX
                }
                return lhs.frame.minY < rhs.frame.minY
            }
            .compactMap { screen -> CapturedSegment? in
                guard
                    let displayID = screen.displayID,
                    let display = displaysByID[displayID]
                else {
                    return nil
                }

                let intersection = rect.intersection(display.frame)
                guard intersection.isNull == false, intersection.isEmpty == false else { return nil }

                return CapturedSegment(
                    screen: screen,
                    display: display,
                    intersection: intersection
                )
            }

        guard orderedSegments.isEmpty == false else {
            throw CaptureError.missingDisplayMetadata
        }

        var renderedSegments: [RenderedSegment] = []
        for segment in orderedSegments {
            let image = try await captureSegment(segment)
            renderedSegments.append(
                RenderedSegment(
                    image: image,
                    intersection: segment.intersection
                )
            )
        }

        let compositeScale = maximumScale(for: screens)
        let pixelWidth = max(1, Int((rect.width * compositeScale).rounded(.up)))
        let pixelHeight = max(1, Int((rect.height * compositeScale).rounded(.up)))

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpace(name: CGColorSpace.displayP3),
            let context = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw CaptureError.imageConstructionFailed
        }

        context.interpolationQuality = .high
        context.clear(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        for segment in renderedSegments {
            let origin = CGPoint(
                x: (segment.intersection.minX - rect.minX) * compositeScale,
                y: (segment.intersection.minY - rect.minY) * compositeScale
            )
            let size = CGSize(
                width: segment.intersection.width * compositeScale,
                height: segment.intersection.height * compositeScale
            )
            context.draw(segment.image, in: CGRect(origin: origin, size: size))
        }

        guard let composite = context.makeImage() else {
            throw CaptureError.imageConstructionFailed
        }

        return composite
    }

    private func captureSegment(_ segment: CapturedSegment) async throws -> CGImage {
        let configuration = SCStreamConfiguration()
        configuration.showsCursor = false
        configuration.capturesAudio = false
        configuration.width = max(1, Int((segment.intersection.width * segment.screen.backingScaleFactor).rounded(.up)))
        configuration.height = max(1, Int((segment.intersection.height * segment.screen.backingScaleFactor).rounded(.up)))
        configuration.sourceRect = sourceRect(for: segment)

        let filter = SCContentFilter(display: segment.display, excludingWindows: [])

        return try await withCheckedThrowingContinuation { continuation in
            SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration) { image, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image else {
                    continuation.resume(throwing: CaptureError.captureUnavailable)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    private func currentShareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.current
    }

    private func sourceRect(for segment: CapturedSegment) -> CGRect {
        // ScreenCaptureKit crops display capture in the display's local coordinate space.
        // AppKit screen selection comes in with a bottom-left origin, so flip Y before capture.
        CGRect(
            x: segment.intersection.minX - segment.display.frame.minX,
            y: segment.display.frame.maxY - segment.intersection.maxY,
            width: segment.intersection.width,
            height: segment.intersection.height
        )
    }

    private func maximumScale(for screens: [NSScreen]) -> CGFloat {
        screens
            .map(\.backingScaleFactor)
            .max() ?? 1
    }
}

private struct CapturedSegment {
    let screen: NSScreen
    let display: SCDisplay
    let intersection: CGRect
}

private struct RenderedSegment {
    let image: CGImage
    let intersection: CGRect
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
            .map { CGDirectDisplayID($0.uint32Value) }
    }
}
