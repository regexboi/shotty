import AppKit
import SwiftUI

struct EditorRootView: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var showsToolControls = false

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
                Button {
                    viewModel.selectTool(tool)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tool.symbolName)
                            .font(.system(size: 15, weight: .semibold))

                        Text(tool.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)

                        Text("[\(tool.shortcutIndex)]")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                            .fixedSize()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(ToolChipButtonStyle(isSelected: viewModel.document.selectedTool == tool))
            }
        }
    }

    private var toolControls: some View {
        HStack(spacing: 18) {
            HStack(spacing: 10) {
                Text("Color")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.lavenderDim)

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
                    .foregroundStyle(ShottyTheme.lavenderDim)

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
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ShottyTheme.shellTop.opacity(0.96),
                                ShottyTheme.surfaceRaised.opacity(0.92),
                                ShottyTheme.shellBottom.opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 30, x: 0, y: 18)
    }

    private var shellStroke: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        ShottyTheme.purpleBright.opacity(0.5),
                        ShottyTheme.surfaceLine.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
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
            .foregroundStyle(ShottyTheme.lavender.opacity(configuration.isPressed ? 0.9 : 0.98))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(configuration.isPressed ? 0.34 : 0.26)
                            : ShottyTheme.surfaceRaised.opacity(configuration.isPressed ? 0.92 : 0.8)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(0.72)
                            : ShottyTheme.surfaceLine.opacity(0.74),
                        lineWidth: 1
                    )
            )
    }
}

private struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(ShottyTheme.lavender.opacity(configuration.isPressed ? 0.84 : 0.94))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ShottyTheme.surfaceRaised.opacity(configuration.isPressed ? 0.96 : 0.84))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ShottyTheme.surfaceLine.opacity(0.72), lineWidth: 1)
            )
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
                            ? ShottyTheme.surfaceRaised.opacity(0.98)
                            : ShottyTheme.surface.opacity(configuration.isPressed ? 0.95 : 0.8)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(0.78)
                            : ShottyTheme.surfaceLine.opacity(0.66),
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
                    ? Color.white.opacity(configuration.isPressed ? 0.92 : 0.98)
                    : ShottyTheme.lavender.opacity(configuration.isPressed ? 0.84 : 0.94)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(configuration.isPressed ? 0.74 : 0.62)
                            : ShottyTheme.surfaceRaised.opacity(configuration.isPressed ? 0.96 : 0.84)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.pinkBright.opacity(0.74)
                            : ShottyTheme.surfaceLine.opacity(0.72),
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
                    .fill(tint.opacity(configuration.isPressed ? 0.42 : 0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint.opacity(0.62), lineWidth: 1)
            )
    }
}
