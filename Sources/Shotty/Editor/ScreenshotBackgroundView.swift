import SwiftUI

struct ScreenshotBackgroundView: View {
    let preset: ScreenshotBackgroundPreset
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: preset.previewColors,
                            startPoint: preset.startPoint,
                            endPoint: preset.endPoint
                        )
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)

                ForEach(Array(preset.glowSpecs.enumerated()), id: \.offset) { entry in
                    let glow = entry.element
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(nsColor: glow.color).opacity(glow.opacity),
                                    .clear
                                ],
                                center: glow.center,
                                startRadius: 12,
                                endRadius: max(proxy.size.width, proxy.size.height) * glow.radiusFraction
                            )
                        )
                }

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.white.opacity(0.03),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.screen)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
