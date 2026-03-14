import AppKit
import Foundation
import SwiftUI

@MainActor
final class EditorViewModel: ObservableObject {
    @Published private(set) var document = EditorDocument.placeholder
    @Published private(set) var statusMessage = "Press Cmd + Shift + S to exercise the Phase 1 hotkey path."
    @Published private(set) var permissionState: CaptureCoordinator.PermissionState = .unknown
    @Published private(set) var hotkeyRegistrationState = "Registering hotkey"

    var onRequestClose: (() -> Void)?
    weak var windowProvider: EditorWindowController?
    private var exportService: ExportService?

    var canvasTitle: String {
        document.capturedImage == nil ? "Foundation shell ready" : "Placeholder capture ready"
    }

    var permissionBadgeTitle: String {
        switch permissionState {
        case .unknown:
            return "Permission needed"
        case .requesting:
            return "Permission prompt active"
        case .granted:
            return "Permission granted"
        case .denied:
            return "Permission denied"
        }
    }

    var permissionBadgeColor: Color {
        switch permissionState {
        case .unknown:
            return ShottyTheme.gold
        case .requesting:
            return ShottyTheme.goldBright
        case .granted:
            return ShottyTheme.purpleBright
        case .denied:
            return .red.opacity(0.9)
        }
    }

    func bindExportService(_ exportService: ExportService) {
        self.exportService = exportService
    }

    func loadInitialState(permissionState: CaptureCoordinator.PermissionState) {
        self.permissionState = permissionState
        statusMessage = "Editor shell is live. Press Cmd + Shift + S to trigger the placeholder capture flow."
    }

    func updatePermissionState(_ permissionState: CaptureCoordinator.PermissionState) {
        self.permissionState = permissionState
    }

    func noteHotkeyRegistrationSucceeded() {
        hotkeyRegistrationState = "Hotkey ready"
        statusMessage = "Global hotkey is registered. Press Cmd + Shift + S from anywhere while Shotty is running."
    }

    func noteHotkeyRegistrationFailed(_ errorDescription: String) {
        hotkeyRegistrationState = "Hotkey unavailable"
        statusMessage = errorDescription
    }

    func noteCaptureRequested() {
        statusMessage = "Capture requested. Permission will be checked before Phase 2 overlay work starts."
    }

    func notePermissionRequestPending() {
        statusMessage = "Shotty is requesting Screen Recording permission. Approve it in the system prompt or System Settings."
    }

    func notePermissionDenied() {
        statusMessage = "Screen Recording permission is not available yet. Use the settings button, then trigger the hotkey again."
    }

    func presentCapturePlaceholder(image: CapturedImage) {
        permissionState = .granted
        document.capturedImage = image
        statusMessage = "Placeholder capture loaded. Region selection and real screenshots arrive in Phase 2."
    }

    func selectTool(_ tool: AnnotationTool) {
        document.selectedTool = tool
        statusMessage = "\(tool.title) selected. Annotation rendering is scaffolded for Phase 3."
    }

    func copyPlaceholderToPasteboard() {
        if exportService?.copyPlaceholder(document: document) == true {
            statusMessage = "Placeholder image copied to the pasteboard."
        } else {
            statusMessage = "Capture placeholder first, then copy will export the current image."
        }
    }

    func savePlaceholderImage() {
        if exportService?.showPlaceholderSavePanel(for: document, from: windowProvider?.window) == true {
            statusMessage = "Save panel opened for the current placeholder image."
        } else {
            statusMessage = "There is no image to save yet. Trigger the placeholder capture path first."
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }

        NSWorkspace.shared.open(url)
        statusMessage = "System Settings opened to Screen Recording."
    }

    func handleEscape() {
        statusMessage = "Editor closed. Re-open it with the Shotty dock icon or trigger the hotkey again."
        onRequestClose?()
    }
}
