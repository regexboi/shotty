import SwiftUI

struct EditorRootView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            toolSwitcher
            canvas
            footer
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
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Shotty")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(viewModel.canvasTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(viewModel.statusMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    badge(
                        title: viewModel.permissionBadgeTitle,
                        tint: viewModel.permissionBadgeColor
                    )

                    badge(
                        title: viewModel.annotationCountLabel,
                        tint: .white.opacity(0.8)
                    )

                    Text("Hotkey: Cmd + Shift + S")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                commandButton("Undo", systemImage: "arrow.uturn.backward") {
                    viewModel.undo()
                }
                .disabled(viewModel.canUndo == false)

                commandButton("Redo", systemImage: "arrow.uturn.forward") {
                    viewModel.redo()
                }
                .disabled(viewModel.canRedo == false)

                commandButton("Copy", systemImage: "doc.on.doc") {
                    viewModel.copyCurrentImageToPasteboard()
                }

                commandButton("Save", systemImage: "square.and.arrow.down") {
                    viewModel.saveCurrentImage()
                }

                commandButton("Settings", systemImage: "gearshape") {
                    viewModel.openSystemSettings()
                }
            }
        }
    }

    private var toolSwitcher: some View {
        HStack(spacing: 12) {
            ForEach(AnnotationTool.allCases) { tool in
                Button {
                    viewModel.selectTool(tool)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Image(systemName: tool.symbolName)
                                .font(.system(size: 15, weight: .semibold))

                            Text(tool.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }

                        Text(tool.shortDescription)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.56))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(ToolChipButtonStyle(isSelected: viewModel.document.selectedTool == tool))
            }
        }
    }

    private var canvas: some View {
        AnnotationCanvasView(viewModel: viewModel)
            .id(viewModel.document.capturedImage?.captureRect.debugDescription ?? "empty-canvas")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            infoCard(
                title: "Active Tool",
                body: "\(viewModel.document.selectedTool.title). \(viewModel.selectedToolDescription)"
            )

            infoCard(
                title: viewModel.selectionStatusTitle,
                body: viewModel.selectionStatusDetail
            )

            infoCard(
                title: viewModel.canUndo || viewModel.canRedo ? "History Ready" : "History Idle",
                body: viewModel.historyStatusDetail
            )
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

    private func badge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.16))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.32), lineWidth: 1)
            )
    }

    private func commandButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
        .buttonStyle(SecondaryPillButtonStyle())
    }

    private func infoCard(title: String, body: String) -> some View {
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

private struct ToolChipButtonStyle: ButtonStyle {
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
