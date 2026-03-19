import AppKit
import CoreGraphics
import Foundation

struct CapturedImage {
    let image: NSImage
    let captureRect: CGRect
    let displayScale: CGFloat
    let balanceFocusRect: CGRect?
}
