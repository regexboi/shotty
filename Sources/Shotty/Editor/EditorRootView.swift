import AppKit
import SwiftUI

struct EditorRootView: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var showsSettingsSidebar = false
    private let shellCornerRadius: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            HStack(alignment: .top, spacing: 18) {
                mainWorkspace

                if showsSettingsSidebar {
                    settingsSidebar
                        .frame(width: 340)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .padding(24)
        .frame(minWidth: 1080, minHeight: 720)
        .background(backgroundShell)
        .overlay(shellStroke)
        .animation(.spring(response: 0.26, dampingFraction: 0.88), value: showsSettingsSidebar)
        .onExitCommand {
            viewModel.handleEscape()
        }
    }

    private var mainWorkspace: some View {
        VStack(alignment: .leading, spacing: 16) {
            toolSwitcher
            canvas
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            dragRegion
            Spacer(minLength: 0)

            HStack(spacing: 10) {
                iconCommandButton(systemImage: "gearshape", help: "Appearance & Tool Settings") {
                    showsSettingsSidebar.toggle()
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

    private var settingsSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsHeader
                toolControls
                appearanceControls
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.048))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 16)
    }

    private var settingsHeader: some View {
        Text("Editor Settings")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(ShottyTheme.goldBright.opacity(0.98))
    }

    private var toolControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Annotation Color")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.goldBright.opacity(0.94))

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 10), count: 6), spacing: 10) {
                    ForEach(AnnotationColorToken.allCases, id: \.rawValue) { color in
                        Button {
                            viewModel.selectAnnotationColor(color)
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 16, height: 16)
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(ColorChipButtonStyle(isSelected: viewModel.currentToolColor == color))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.document.selectedTool == .text ? "Font Size" : "Stroke Size")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.goldBright.opacity(0.94))

                HStack(spacing: 8) {
                    ForEach(AnnotationSizePreset.allCases) { sizePreset in
                        Button {
                            viewModel.selectAnnotationSizePreset(sizePreset)
                        } label: {
                            Text(sizePreset.title.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(SizeChipButtonStyle(isSelected: viewModel.currentToolSizePreset == sizePreset))
                    }
                }
            }
        }
    }

    private var appearanceControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                appearanceToggle(
                    title: "Background",
                    isOn: Binding(
                        get: { viewModel.document.appearance.backgroundModeEnabled },
                        set: { viewModel.setBackgroundModeEnabled($0) }
                    )
                )

                appearanceToggle(
                    title: "Balance",
                    isOn: Binding(
                        get: { viewModel.document.appearance.balanceEnabled },
                        set: { viewModel.setBalanceEnabled($0) }
                    )
                )
                .disabled(viewModel.document.appearance.backgroundModeEnabled == false)
                .opacity(viewModel.document.appearance.backgroundModeEnabled ? 1 : 0.58)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Backgrounds")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.goldBright.opacity(0.94))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(ScreenshotBackgroundPreset.allCases) { preset in
                        Button {
                            viewModel.selectBackgroundPreset(preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                ScreenshotBackgroundView(preset: preset, cornerRadius: 12)
                                    .frame(height: 64)

                                Text(preset.title)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(ShottyTheme.lavender.opacity(0.96))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(BackgroundPresetButtonStyle(isSelected: viewModel.document.appearance.backgroundPreset == preset))
                        .disabled(viewModel.document.appearance.backgroundModeEnabled == false)
                        .opacity(viewModel.document.appearance.backgroundModeEnabled ? 1 : 0.56)
                    }
                }
            }

            appearanceSlider(
                title: "Padding",
                value: Binding(
                    get: { Double(viewModel.document.appearance.padding) },
                    set: { viewModel.setBackgroundPadding(CGFloat($0)) }
                ),
                range: ScreenshotAppearance.paddingRange,
                valueLabel: "\(Int(viewModel.document.appearance.clampedPadding.rounded())) px"
            )
            .disabled(viewModel.document.appearance.backgroundModeEnabled == false)
            .opacity(viewModel.document.appearance.backgroundModeEnabled ? 1 : 0.58)

            appearanceSlider(
                title: "Inset",
                value: Binding(
                    get: { Double(viewModel.document.appearance.inset) },
                    set: { viewModel.setImageInset(CGFloat($0)) }
                ),
                range: ScreenshotAppearance.insetRange,
                valueLabel: "\(Int(viewModel.document.appearance.clampedInset.rounded())) px"
            )

            appearanceSlider(
                title: "Radius",
                value: Binding(
                    get: { Double(viewModel.document.appearance.cornerRadius) },
                    set: { viewModel.setImageCornerRadius(CGFloat($0)) }
                ),
                range: ScreenshotAppearance.cornerRadiusRange,
                valueLabel: "\(Int(viewModel.document.appearance.clampedCornerRadius.rounded())) px"
            )

            appearanceSlider(
                title: "Shadow",
                value: Binding(
                    get: { Double(viewModel.document.appearance.shadow) },
                    set: { viewModel.setImageShadow(CGFloat($0)) }
                ),
                range: ScreenshotAppearance.shadowRange,
                valueLabel: "\(Int(viewModel.document.appearance.clampedShadow.rounded())) px"
            )
            .disabled(viewModel.document.appearance.backgroundModeEnabled == false)
            .opacity(viewModel.document.appearance.backgroundModeEnabled ? 1 : 0.58)
        }
    }

    private var canvas: some View {
        NonDraggableHostingRegion {
            AnnotationCanvasView(viewModel: viewModel)
                .id(viewModel.document.capturedImage?.id.uuidString ?? "empty-canvas")
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

    private func appearanceToggle(
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(ShottyTheme.goldBright.opacity(0.96))

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private func appearanceSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        valueLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ShottyTheme.goldBright.opacity(0.94))

                Spacer(minLength: 0)

                Text(valueLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(ShottyTheme.lavender.opacity(0.88))
            }

            Slider(value: value, in: range)
                .tint(ShottyTheme.goldBright)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct ColorChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(configuration.isPressed ? 0.20 : 0.14)
                            : Color.white.opacity(configuration.isPressed ? 0.08 : 0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.goldBright.opacity(0.82)
                            : Color.white.opacity(0.10),
                        lineWidth: 1
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

private struct BackgroundPresetButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? ShottyTheme.purpleBright.opacity(configuration.isPressed ? 0.20 : 0.14)
                            : Color.white.opacity(configuration.isPressed ? 0.08 : 0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? ShottyTheme.goldBright.opacity(0.82)
                            : Color.white.opacity(0.10),
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
