import SwiftUI

struct EditorRootView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        HStack(spacing: 22) {
            toolStrip
            canvasColumn
        }
        .padding(24)
        .frame(minWidth: 920, minHeight: 620)
        .background(backgroundShell)
        .overlay(shellStroke)
        .onExitCommand {
            viewModel.handleEscape()
        }
    }

    private var toolStrip: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shotty")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))

                Text("Minimal screenshot utility")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 10) {
                ForEach(AnnotationTool.allCases) { tool in
                    Button {
                        viewModel.selectTool(tool)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tool.symbolName)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                Text(tool.shortDescription)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.58))
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ToolButtonStyle(isSelected: viewModel.document.selectedTool == tool))
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 10) {
                actionButton("Copy Current Image", systemImage: "doc.on.doc") {
                    viewModel.copyCurrentImageToPasteboard()
                }

                actionButton("Save Current Image", systemImage: "square.and.arrow.down") {
                    viewModel.saveCurrentImage()
                }

                actionButton("Open Screen Recording Settings", systemImage: "gearshape") {
                    viewModel.openSystemSettings()
                }
            }
        }
        .frame(width: 268, alignment: .topLeading)
    }

    private var canvasColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.canvasTitle)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(viewModel.statusMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(viewModel.permissionBadgeTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(viewModel.permissionBadgeColor.opacity(0.18))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(viewModel.permissionBadgeColor.opacity(0.32), lineWidth: 1)
                        )

                    Text("Hotkey: Cmd + Shift + S")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.52))
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ShottyTheme.canvasBaseTop,
                                ShottyTheme.canvasBaseBottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)

                if let capturedImage = viewModel.document.capturedImage {
                    Image(nsImage: capturedImage.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(24)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "viewfinder.circle")
                            .font(.system(size: 54, weight: .regular))
                            .foregroundStyle(ShottyTheme.goldBright.opacity(0.9))

                        Text("Capture preview lands here")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.94))

                        Text("Launch the app, hit the global hotkey, and the selected screenshot will appear here.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                    }
                    .padding(32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                Text("Capture Notes")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))

                HStack(spacing: 12) {
                    noteCard(
                        title: "Editor shell",
                        body: "Glassy SwiftUI workspace is live and hosted inside an AppKit window controller."
                    )

                    noteCard(
                        title: "Capture path",
                        body: "The global hotkey now opens a real multi-display selection overlay and routes the resulting screenshot into the editor."
                    )

                    noteCard(
                        title: "Keyboard",
                        body: "Esc cancels capture or closes the editor shell. Copy/save currently export the raw captured image."
                    )
                }
            }
        }
    }

    private var backgroundShell: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ShottyTheme.shellTop.opacity(0.92),
                                ShottyTheme.shellBottom.opacity(0.84)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 30, x: 0, y: 18)
    }

    private var shellStroke: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        .white.opacity(0.28),
                        .white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryPillButtonStyle())
    }

    private func noteCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Text(body)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ToolButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.9 : 0.96))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? ShottyTheme.purpleBright.opacity(0.28) : .white.opacity(configuration.isPressed ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? ShottyTheme.purpleBright.opacity(0.5) : .white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.84 : 0.92))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.11 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
    }
}
