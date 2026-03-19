import AppKit
import CoreGraphics
import Foundation
import SwiftUI

struct ScreenshotAppearance: Equatable {
    static let paddingRange: ClosedRange<Double> = 0 ... 220
    static let insetRange: ClosedRange<Double> = 0 ... 120
    static let cornerRadiusRange: ClosedRange<Double> = 0 ... 48
    static let shadowRange: ClosedRange<Double> = 0 ... 48

    var backgroundModeEnabled = false
    var backgroundPreset: ScreenshotBackgroundPreset = .aurora
    var padding: CGFloat = 88
    var inset: CGFloat = 0
    var cornerRadius: CGFloat = 22
    var shadow: CGFloat = 28
    var balanceEnabled = true

    init(
        backgroundModeEnabled: Bool = false,
        backgroundPreset: ScreenshotBackgroundPreset = .aurora,
        padding: CGFloat = 88,
        inset: CGFloat = 0,
        cornerRadius: CGFloat = 22,
        shadow: CGFloat = 28,
        balanceEnabled: Bool = true
    ) {
        self.backgroundModeEnabled = backgroundModeEnabled
        self.backgroundPreset = backgroundPreset
        self.padding = padding
        self.inset = inset
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.balanceEnabled = balanceEnabled
    }

    var clampedPadding: CGFloat {
        CGFloat(min(max(Double(padding), Self.paddingRange.lowerBound), Self.paddingRange.upperBound))
    }

    var clampedInset: CGFloat {
        CGFloat(min(max(Double(inset), Self.insetRange.lowerBound), Self.insetRange.upperBound))
    }

    var clampedCornerRadius: CGFloat {
        CGFloat(min(max(Double(cornerRadius), Self.cornerRadiusRange.lowerBound), Self.cornerRadiusRange.upperBound))
    }

    var clampedShadow: CGFloat {
        CGFloat(min(max(Double(shadow), Self.shadowRange.lowerBound), Self.shadowRange.upperBound))
    }
}

enum ScreenshotBackgroundPreset: String, Codable, CaseIterable, Identifiable {
    case aurora
    case daybreak
    case lagoon
    case ember
    case graphite
    case purpleRain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora:
            return "Aurora"
        case .daybreak:
            return "Daybreak"
        case .lagoon:
            return "Lagoon"
        case .ember:
            return "Ember"
        case .graphite:
            return "Graphite"
        case .purpleRain:
            return "Purple Rain"
        }
    }

    var gradientColors: [NSColor] {
        switch self {
        case .aurora:
            return [
                .init(red: 0.207, green: 0.113, blue: 0.478, alpha: 1),
                .init(red: 0.431, green: 0.220, blue: 0.886, alpha: 1),
                .init(red: 0.039, green: 0.792, blue: 0.961, alpha: 1)
            ]
        case .daybreak:
            return [
                .init(red: 0.424, green: 0.129, blue: 0.380, alpha: 1),
                .init(red: 0.965, green: 0.514, blue: 0.302, alpha: 1),
                .init(red: 0.996, green: 0.822, blue: 0.388, alpha: 1)
            ]
        case .lagoon:
            return [
                .init(red: 0.031, green: 0.251, blue: 0.333, alpha: 1),
                .init(red: 0.082, green: 0.522, blue: 0.584, alpha: 1),
                .init(red: 0.259, green: 0.761, blue: 0.855, alpha: 1)
            ]
        case .ember:
            return [
                .init(red: 0.204, green: 0.110, blue: 0.176, alpha: 1),
                .init(red: 0.682, green: 0.192, blue: 0.157, alpha: 1),
                .init(red: 0.969, green: 0.596, blue: 0.231, alpha: 1)
            ]
        case .graphite:
            return [
                .init(red: 0.086, green: 0.106, blue: 0.149, alpha: 1),
                .init(red: 0.169, green: 0.220, blue: 0.302, alpha: 1),
                .init(red: 0.392, green: 0.459, blue: 0.584, alpha: 1)
            ]
        case .purpleRain:
            return [
                .init(red: 0.071, green: 0.008, blue: 0.165, alpha: 1),
                .init(red: 0.357, green: 0.176, blue: 0.557, alpha: 1),
                .init(red: 0.102, green: 0.020, blue: 0.200, alpha: 1)
            ]
        }
    }

    var previewColors: [Color] {
        gradientColors.map(Color.init(nsColor:))
    }

    var startPoint: UnitPoint {
        switch self {
        case .aurora:
            return .topLeading
        case .daybreak:
            return .top
        case .lagoon:
            return .leading
        case .ember:
            return .topLeading
        case .graphite:
            return .top
        case .purpleRain:
            return .topLeading
        }
    }

    var endPoint: UnitPoint {
        switch self {
        case .aurora:
            return .bottomTrailing
        case .daybreak:
            return .bottomTrailing
        case .lagoon:
            return .bottomTrailing
        case .ember:
            return .bottomTrailing
        case .graphite:
            return .bottom
        case .purpleRain:
            return .bottomTrailing
        }
    }

    var glowSpecs: [ScreenshotBackgroundGlow] {
        switch self {
        case .aurora:
            return [
                ScreenshotBackgroundGlow(color: .init(red: 0.980, green: 0.882, blue: 0.424, alpha: 1), center: .topTrailing, radiusFraction: 0.82, opacity: 0.18),
                ScreenshotBackgroundGlow(color: .init(red: 0.086, green: 0.925, blue: 0.984, alpha: 1), center: .bottomLeading, radiusFraction: 0.76, opacity: 0.14)
            ]
        case .daybreak:
            return [
                ScreenshotBackgroundGlow(color: .init(red: 1, green: 0.933, blue: 0.702, alpha: 1), center: .topLeading, radiusFraction: 0.88, opacity: 0.20),
                ScreenshotBackgroundGlow(color: .init(red: 0.996, green: 0.561, blue: 0.659, alpha: 1), center: .bottomTrailing, radiusFraction: 0.70, opacity: 0.12)
            ]
        case .lagoon:
            return [
                ScreenshotBackgroundGlow(color: .init(red: 0.424, green: 0.933, blue: 0.953, alpha: 1), center: .topTrailing, radiusFraction: 0.86, opacity: 0.17),
                ScreenshotBackgroundGlow(color: .init(red: 0.176, green: 0.576, blue: 0.984, alpha: 1), center: .bottomLeading, radiusFraction: 0.72, opacity: 0.12)
            ]
        case .ember:
            return [
                ScreenshotBackgroundGlow(color: .init(red: 1, green: 0.776, blue: 0.431, alpha: 1), center: .topTrailing, radiusFraction: 0.82, opacity: 0.18),
                ScreenshotBackgroundGlow(color: .init(red: 0.882, green: 0.231, blue: 0.267, alpha: 1), center: .bottomLeading, radiusFraction: 0.76, opacity: 0.12)
            ]
        case .graphite:
            return [
                ScreenshotBackgroundGlow(color: .init(red: 0.498, green: 0.749, blue: 0.988, alpha: 1), center: .top, radiusFraction: 0.94, opacity: 0.14),
                ScreenshotBackgroundGlow(color: .init(red: 0.980, green: 0.980, blue: 1, alpha: 1), center: .bottomTrailing, radiusFraction: 0.74, opacity: 0.08)
            ]
        case .purpleRain:
            return [
                ScreenshotBackgroundGlow(color: .init(red: 0.706, green: 0.302, blue: 1.000, alpha: 1), center: .top, radiusFraction: 0.92, opacity: 0.22),
                ScreenshotBackgroundGlow(color: .init(red: 1.000, green: 0.349, blue: 0.839, alpha: 1), center: .topTrailing, radiusFraction: 0.76, opacity: 0.16),
                ScreenshotBackgroundGlow(color: .init(red: 0.000, green: 0.898, blue: 1.000, alpha: 1), center: .bottomLeading, radiusFraction: 0.74, opacity: 0.14),
                ScreenshotBackgroundGlow(color: .init(red: 1.000, green: 0.855, blue: 0.271, alpha: 1), center: .bottomTrailing, radiusFraction: 0.58, opacity: 0.10)
            ]
        }
    }
}

struct ScreenshotBackgroundGlow: Equatable {
    let color: NSColor
    let center: UnitPoint
    let radiusFraction: CGFloat
    let opacity: CGFloat
}
