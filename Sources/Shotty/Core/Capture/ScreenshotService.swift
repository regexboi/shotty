import AppKit
import Foundation

@MainActor
final class ScreenshotService {
    func makePlaceholderImage() -> CapturedImage {
        let size = NSSize(width: 1440, height: 900)
        let image = NSImage(size: size)

        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: size)
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.08, green: 0.07, blue: 0.15, alpha: 1.0),
            NSColor(calibratedRed: 0.18, green: 0.10, blue: 0.34, alpha: 1.0),
            NSColor(calibratedRed: 0.34, green: 0.21, blue: 0.71, alpha: 1.0)
        ])

        gradient?.draw(in: bounds, angle: 135)

        NSColor.white.withAlphaComponent(0.14).setStroke()
        let insetFrame = bounds.insetBy(dx: 96, dy: 96)
        let framePath = NSBezierPath(roundedRect: insetFrame, xRadius: 28, yRadius: 28)
        framePath.lineWidth = 4
        framePath.stroke()

        let dashedPath = NSBezierPath(rect: insetFrame.insetBy(dx: 24, dy: 24))
        let pattern: [CGFloat] = [14, 10]
        dashedPath.setLineDash(pattern, count: pattern.count, phase: 0)
        dashedPath.lineWidth = 2
        dashedPath.stroke()

        let title = NSString(string: "Phase 1 Placeholder Capture")
        title.draw(
            at: NSPoint(x: 120, y: size.height - 210),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 40, weight: .semibold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.95)
            ]
        )

        let subtitle = NSString(string: "Hotkey and permission flow are wired. Region selection lands in Phase 2.")
        subtitle.draw(
            at: NSPoint(x: 120, y: size.height - 260),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.78)
            ]
        )

        image.unlockFocus()

        return CapturedImage(
            image: image,
            captureRect: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height)),
            displayScale: NSScreen.main?.backingScaleFactor ?? 2.0
        )
    }
}
