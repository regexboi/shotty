import AppKit
import Foundation
import SwiftUI

@MainActor
final class EditorViewModel: ObservableObject {
    @Published private(set) var document = EditorDocument.placeholder
    @Published private(set) var statusMessage = "Press Cmd + Shift + S to capture a screen region."
    @Published private(set) var permissionState: CaptureCoordinator.PermissionState = .unknown
    @Published private(set) var hotkeyRegistrationState = "Registering hotkey"

    var onRequestClose: (() -> Void)?
    weak var windowProvider: EditorWindowController?
    private var exportService: ExportService?

    var canvasTitle: String {
        document.capturedImage == nil ? "Capture preview" : "Latest capture"
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
        statusMessage = "Editor shell is live. Press Cmd + Shift + S to launch the region capture overlay."
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
        statusMessage = "Capture requested. Shotty is preparing the selection overlay."
    }

    func noteCaptureAlreadyInProgress() {
        statusMessage = "A capture session is already active. Finish or cancel the current selection first."
    }

    func noteSelectionStarted() {
        statusMessage = "Drag to select a region. Press Esc to cancel the capture."
    }

    func noteCaptureProcessing() {
        statusMessage = "Selection complete. Capturing the chosen region now."
    }

    func noteCaptureCancelled() {
        statusMessage = "Capture cancelled. Press Cmd + Shift + S to try again."
    }

    func noteCaptureFailure(_ message: String) {
        statusMessage = message
    }

    func notePermissionRequestPending() {
        statusMessage = "Shotty is requesting Screen Recording permission. Approve it in the system prompt or System Settings."
    }

    func notePermissionDenied() {
        statusMessage = "Screen Recording permission is not available yet. Use the settings button, then trigger the hotkey again."
    }

    func presentCapture(image: CapturedImage) {
        permissionState = .granted
        document.capturedImage = image
        statusMessage = "Capture ready in the editor. Annotation tools land in Phase 3."
    }

    func selectTool(_ tool: AnnotationTool) {
        document.selectedTool = tool
        statusMessage = "\(tool.title) selected. Annotation rendering is scaffolded for Phase 3."
    }

    func copyCurrentImageToPasteboard() {
        if exportService?.copyCurrentImage(document: document) == true {
            statusMessage = "Current image copied to the pasteboard."
        } else {
            statusMessage = "Capture an image first, then copy will export the current image."
        }
    }

    func saveCurrentImage() {
        if exportService?.showSavePanel(for: document, from: windowProvider?.window) == true {
            statusMessage = "Save panel opened for the current image."
        } else {
            statusMessage = "There is no image to save yet. Capture something first."
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
