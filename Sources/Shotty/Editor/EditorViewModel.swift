import AppKit
import Foundation
import SwiftUI

@MainActor
final class EditorViewModel: ObservableObject {
    @Published private(set) var document = EditorDocument.placeholder
    @Published private(set) var statusMessage = "Press Cmd + Shift + S to capture a screen region."
    @Published private(set) var permissionState: CaptureCoordinator.PermissionState = .unknown
    @Published private(set) var hotkeyRegistrationState = "Registering hotkey"
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    @Published private(set) var textEditingAnnotationID: UUID?

    var onRequestClose: (() -> Void)?
    weak var windowProvider: EditorWindowController?
    private var exportService: ExportService?
    private var undoStack: [EditorHistoryState] = []
    private var redoStack: [EditorHistoryState] = []

    var canvasTitle: String {
        document.capturedImage == nil ? "Capture preview" : "Annotate capture"
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

    var selectedToolDescription: String {
        document.selectedTool.shortDescription
    }

    var selectionStatusTitle: String {
        guard let annotation = selectedAnnotation else {
            return document.annotations.isEmpty ? "No annotations yet" : "Nothing selected"
        }

        switch annotation.tool {
        case .text:
            return "Text selected"
        case .pencil:
            return "Pencil stroke selected"
        case .rectangle:
            return "Rectangle selected"
        case .circle:
            return "Circle selected"
        case .highlight:
            return "Highlight selected"
        }
    }

    var selectionStatusDetail: String {
        guard let annotation = selectedAnnotation else {
            return document.annotations.isEmpty
                ? "Use the tool switcher, then click or drag on the screenshot to add annotations."
                : "Click an annotation to select it, press Delete to remove it, or keep drawing with the active tool."
        }

        if annotation.tool == .text {
            return isTextEditing
                ? "Inline text editing is active. Press Return to finish or click away to commit."
                : "Click with the text tool to edit inline, or press Delete to remove the text annotation."
        }

        return "Selection is delete-only in Phase 3. Layering stays in creation order and selected items are outlined."
    }

    var historyStatusDetail: String {
        if canUndo == false && canRedo == false {
            return "Undo stack is empty until you create, edit, or delete an annotation."
        }

        return "Cmd + Z undoes the last annotation change. Shift + Cmd + Z reapplies it."
    }

    var annotationCountLabel: String {
        let count = document.annotations.count
        return count == 1 ? "1 annotation" : "\(count) annotations"
    }

    var hasSelection: Bool {
        document.selectedAnnotationID != nil
    }

    var isTextEditing: Bool {
        textEditingAnnotationID != nil
    }

    var selectedAnnotation: AnnotationSnapshot? {
        guard let selectedID = document.selectedAnnotationID else { return nil }
        return annotation(withID: selectedID)
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
        let selectedTool = document.selectedTool
        document = EditorDocument(
            capturedImage: image,
            annotations: [],
            selectedTool: selectedTool,
            selectedAnnotationID: nil
        )
        textEditingAnnotationID = nil
        undoStack.removeAll()
        redoStack.removeAll()
        updateHistoryAvailability()
        permissionState = .granted
        statusMessage = "Capture ready. Draw annotations, press Delete for the selection, or use Cmd + Z to undo."
    }

    func selectTool(_ tool: AnnotationTool) {
        document.selectedTool = tool

        if tool != .text {
            textEditingAnnotationID = nil
        }

        statusMessage = "\(tool.title) selected. \(tool.shortDescription)"
    }

    func copyCurrentImageToPasteboard() {
        if exportService?.copyCurrentImage(document: document) == true {
            statusMessage = "Current annotated image copied to the pasteboard."
        } else {
            statusMessage = "Capture an image first, then copy will export the current editor image."
        }
    }

    func saveCurrentImage() {
        if exportService?.showSavePanel(for: document, from: windowProvider?.window) == true {
            statusMessage = "Save panel opened for the current annotated image."
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

    func annotation(withID id: UUID) -> AnnotationSnapshot? {
        document.annotations.first { $0.id == id }
    }

    func selectAnnotation(_ id: UUID?) {
        document.selectedAnnotationID = id

        if textEditingAnnotationID != id {
            textEditingAnnotationID = nil
        }

        guard let annotation = selectedAnnotation else {
            statusMessage = document.annotations.isEmpty
                ? "No annotations yet. Choose a tool and start drawing."
                : "Selection cleared."
            return
        }

        statusMessage = "\(annotation.tool.title) selected."
    }

    @discardableResult
    func addAnnotation(_ annotation: AnnotationSnapshot, shouldSelect: Bool = true) -> UUID {
        recordHistoryMutation(
            status: "\(annotation.tool.title) annotation added."
        ) {
            document.annotations.append(annotation)
            document.selectedAnnotationID = shouldSelect ? annotation.id : nil
        }

        if annotation.tool != .text {
            textEditingAnnotationID = nil
        }

        return annotation.id
    }

    @discardableResult
    func createTextAnnotation(at origin: CGPoint) -> UUID {
        let annotation = AnnotationSnapshot.makeText(at: origin)
        let id = addAnnotation(annotation)
        textEditingAnnotationID = id
        statusMessage = "Text annotation placed. Type to edit inline."
        return id
    }

    func beginTextEditing(annotationID: UUID) {
        guard annotation(withID: annotationID)?.tool == .text else { return }
        document.selectedAnnotationID = annotationID
        textEditingAnnotationID = annotationID
        statusMessage = "Inline text editing active."
    }

    func commitTextEdit(annotationID: UUID, text: String) {
        guard let current = annotation(withID: annotationID) else {
            textEditingAnnotationID = nil
            return
        }

        defer {
            textEditingAnnotationID = nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            deleteAnnotation(id: annotationID, status: "Empty text annotation removed.")
            return
        }

        let updated = current.updatedText(text)
        guard updated != current else {
            statusMessage = "Text annotation kept."
            return
        }

        recordHistoryMutation(status: "Text annotation updated.") {
            replaceAnnotation(annotationID: annotationID, with: updated)
            document.selectedAnnotationID = annotationID
        }
    }

    func cancelTextEditing() {
        textEditingAnnotationID = nil
    }

    func deleteSelectedAnnotation() {
        guard let selectedID = document.selectedAnnotationID else {
            statusMessage = "Nothing is selected."
            return
        }

        deleteAnnotation(id: selectedID, status: "Selected annotation deleted.")
    }

    func undo() {
        guard let previousState = undoStack.popLast() else {
            statusMessage = "Nothing to undo."
            return
        }

        redoStack.append(currentHistoryState)
        restoreHistoryState(previousState)
        updateHistoryAvailability()
        statusMessage = "Undo applied."
    }

    func redo() {
        guard let nextState = redoStack.popLast() else {
            statusMessage = "Nothing to redo."
            return
        }

        undoStack.append(currentHistoryState)
        restoreHistoryState(nextState)
        updateHistoryAvailability()
        statusMessage = "Redo applied."
    }

    func handleEscape() {
        if isTextEditing {
            cancelTextEditing()
            statusMessage = "Inline text editing cancelled."
            return
        }

        statusMessage = "Editor closed. Re-open it with the Shotty dock icon or trigger the hotkey again."
        onRequestClose?()
    }

    private var currentHistoryState: EditorHistoryState {
        EditorHistoryState(
            annotations: document.annotations,
            selectedAnnotationID: document.selectedAnnotationID
        )
    }

    private func restoreHistoryState(_ state: EditorHistoryState) {
        document.annotations = state.annotations
        document.selectedAnnotationID = state.selectedAnnotationID
        textEditingAnnotationID = nil
    }

    private func deleteAnnotation(id: UUID, status: String) {
        guard annotation(withID: id) != nil else { return }

        recordHistoryMutation(status: status) {
            document.annotations.removeAll { $0.id == id }
            if document.selectedAnnotationID == id {
                document.selectedAnnotationID = nil
            }
        }

        if textEditingAnnotationID == id {
            textEditingAnnotationID = nil
        }
    }

    private func replaceAnnotation(annotationID: UUID, with updatedAnnotation: AnnotationSnapshot) {
        guard let index = document.annotations.firstIndex(where: { $0.id == annotationID }) else { return }
        document.annotations[index] = updatedAnnotation
    }

    private func recordHistoryMutation(status: String, _ mutation: () -> Void) {
        let before = currentHistoryState
        mutation()
        let after = currentHistoryState

        guard before != after else { return }

        undoStack.append(before)
        redoStack.removeAll()
        updateHistoryAvailability()
        statusMessage = status
    }

    private func updateHistoryAvailability() {
        canUndo = undoStack.isEmpty == false
        canRedo = redoStack.isEmpty == false
    }
}

private struct EditorHistoryState: Equatable {
    let annotations: [AnnotationSnapshot]
    let selectedAnnotationID: UUID?
}
