import AppKit
import CoreGraphics
import Foundation

struct CapturedImage {
    let id = UUID()
    let image: NSImage
    let captureRect: CGRect
    let displayScale: CGFloat
    let balanceFocusRect: CGRect?
}
