import AppKit
import SwiftUI

struct EditorRootView: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var showsToolControls = false
    private let shellCornerRadius: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            toolSwitcher
            if showsToolControls {
                toolControls
            }
            canvas
        }
        .padding(24)
        .frame(minWidth: 980, minHeight: 720)
        .background(backgroundShell)
        .overlay(shellStroke)
        .onExitCommand {
            viewModel.handleEscape()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            dragRegion
            Spacer(minLength: 0)

            HStack(spacing: 10) {
                iconCommandButton(systemImage: "gearshape", help: "Tool Settings") {
                    showsToolControls.toggle()
                }

                iconCommandButton(systemImage: "arrow.uturn.backward", help: "Undo") {
                    viewModel.undo()
                }
                .disabled(viewModel.canUndo == false)

                iconCommandButton(systemImage: "arrow.uturn.forward", help: "Redo") {
                    viewModel.redo()
                }
                .disabled(viewModel.canRedo == false)

                iconCommandButton(systemImage: "doc.on.doc", help: "Copy") {
                    viewModel.copyCurrentImageToPasteboard()
                }

                iconCommandButton(systemImage: "square.and.arrow.down", help: "Save") {
                    viewModel.saveCurrentImage()
                }

                permissionSettingsButton {
                    viewModel.openSystemSettings()
                }
            }
        }
    }

    private var dragRegion: some View {
        Group {
            if let logoImage = shottyLogoImage {
                Image(nsImage: logoImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 66, height: 66)
                    .padding(.leading, 2)
            } else {
                Color.clear
                    .frame(width: 66, height: 66)
            }
        }
        .frame(width: 68, height: 66, alignment: .leading)
    }

    private var toolSwitcher: some View {
        HStack(spacing: 12) {
            ForEach(AnnotationTool.allCases) { tool in
                let isSelected = viewModel.document.selectedTool == tool

                Button {
                    viewModel.selectTool(tool)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tool.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                isSelected
                                    ? ShottyTheme.goldBright
                                    : ShottyTheme.gold.opacity(0.88)
                            )

                        Text(tool.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                isSelected
                                    ? ShottyTheme.goldBright
                                    : ShottyTheme.lavender.opacity(0.94)
                            )
                            .lineLimit(1)

                        Text("[\(tool.shortcutIndex)]")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                isSelected
                                    ? ShottyTheme.goldBright.opacity(0.96)
                                    : ShottyTheme.lavenderDim.opacity(0.78)
                            )
                            .fixedSize()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(ToolChipButtonStyle(isSelected: isSelected))
            }
        }
    }

    private var toolControls: some View {
        HStack(spacing: 18) {
            HStack(spacing: 10) {
                Text("Color")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.goldBright.opacity(0.94))

                HStack(spacing: 8) {
                    ForEach(AnnotationColorToken.allCases, id: \.rawValue) { color in
                        Button {
                            viewModel.selectAnnotationColor(color)
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(ColorSwatchButtonStyle(isSelected: viewModel.currentToolColor == color))
                        .help(color.title)
                    }
                }
            }

            HStack(spacing: 10) {
                Text(viewModel.document.selectedTool == .text ? "Font" : "Size")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.goldBright.opacity(0.94))

                HStack(spacing: 8) {
                    ForEach(AnnotationSizePreset.allCases) { sizePreset in
                        Button {
                            viewModel.selectAnnotationSizePreset(sizePreset)
                        } label: {
                            Text(sizePreset.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .frame(minWidth: 28)
                        }
                        .buttonStyle(SizeChipButtonStyle(isSelected: viewModel.currentToolSizePreset == sizePreset))
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var canvas: some View {
        NonDraggableHostingRegion {
            AnnotationCanvasView(viewModel: viewModel)
                .id(viewModel.document.capturedImage?.captureRect.debugDescription ?? "empty-canvas")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backgroundShell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ShottyTheme.shellTop.opacity(0.76),
                            ShottyTheme.surfaceRaised.opacity(0.28),
                            ShottyTheme.shellBottom.opacity(0.74)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ShottyTheme.surfaceDeep.opacity(0.44),
                            Color.clear,
                            ShottyTheme.surfaceDeep.opacity(0.32)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            ShottyTheme.goldBright.opacity(0.08),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 18,
                        endRadius: 260
                    )
                )

            RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            ShottyTheme.cyanBright.opacity(0.05),
                            Color.clear
                        ],
                        center: .bottomLeading,
                        startRadius: 14,
                        endRadius: 240
                    )
                )

            RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.11),
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blendMode(.screen)
        }
        .clipShape(RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous))
        .shadow(color: ShottyTheme.purpleAccent.opacity(0.16), radius: 28, x: 0, y: 14)
        .shadow(color: .black.opacity(0.16), radius: 44, x: 0, y: 22)
    }

    private var shellStroke: some View {
        RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        ShottyTheme.goldBright.opacity(0.22),
                        ShottyTheme.surfaceLine.opacity(0.30),
                        ShottyTheme.purpleBright.opacity(0.26)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .overlay {
                RoundedRectangle(cornerRadius: shellCornerRadius - 1, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.clear,
                                ShottyTheme.gold.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
    }

    private func iconCommandButton(
        systemImage: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(SecondaryPillButtonStyle())
        .help(help)
    }

    private func permissionSettingsButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "apple.logo")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(PermissionPillButtonStyle(tint: viewModel.permissionBadgeColor))
        .help(viewModel.permissionBadgeTitle)
    }
}

private var shottyLogoImage: NSImage? {
    guard let url = Bundle.module.url(forResource: "logo", withExtension: "png") else {
        return nil
    }

    return NSImage(contentsOf: url)
}

private struct NonDraggableHostingRegion<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NonDraggableHostingView<Content> {
        let hostingView = NonDraggableHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        return hostingView
    }

    func updateNSView(_ nsView: NonDraggableHostingView<Content>, context: Context) {
        nsView.rootView = content
    }
}

private final class NonDraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
}

private struct ToolChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(configuration.isPressed ? 0.28 : 0.18)
                            : Color.white.opacity(configuration.isPressed ? 0.09 : 0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.goldBright.opacity(0.78)
                            : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? ShottyTheme.gold.opacity(0.18) : .clear,
                radius: 16,
                x: 0,
                y: 8
            )
    }
}

private struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(ShottyTheme.goldBright.opacity(configuration.isPressed ? 0.82 : 0.96))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.09 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: ShottyTheme.gold.opacity(0.10), radius: 12, x: 0, y: 6)
    }
}

private struct ColorSwatchButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.white.opacity(0.13)
                            : Color.white.opacity(configuration.isPressed ? 0.09 : 0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.goldBright.opacity(0.82)
                            : Color.white.opacity(0.12),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
    }
}

private struct SizeChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(
                isSelected
                    ? ShottyTheme.goldBright.opacity(configuration.isPressed ? 0.90 : 0.98)
                    : ShottyTheme.lavender.opacity(configuration.isPressed ? 0.84 : 0.94)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? ShottyTheme.gold.opacity(configuration.isPressed ? 0.22 : 0.16)
                            : Color.white.opacity(configuration.isPressed ? 0.09 : 0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.goldBright.opacity(0.84)
                            : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
    }
}

private struct PermissionPillButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.86 : 0.96))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.opacity(configuration.isPressed ? 0.24 : 0.18))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint.opacity(0.62), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
