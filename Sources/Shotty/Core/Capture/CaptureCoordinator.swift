import CoreGraphics
import Foundation

@MainActor
final class CaptureCoordinator {
    enum PermissionState: Equatable {
        case unknown
        case requesting
        case granted
        case denied
    }

    private let editorViewModel: EditorViewModel
    private let editorWindowController: EditorWindowController
    private let screenshotService: ScreenshotService
    private let selectionOverlayWindow = SelectionOverlayWindow()
    private var isCaptureInProgress = false
    private var isPermissionRequestInProgress = false

    init(
        editorViewModel: EditorViewModel,
        editorWindowController: EditorWindowController,
        screenshotService: ScreenshotService
    ) {
        self.editorViewModel = editorViewModel
        self.editorWindowController = editorWindowController
        self.screenshotService = screenshotService
    }

    func prepareInitialExperience() {
        editorViewModel.loadInitialState(
            permissionState: CGPreflightScreenCaptureAccess() ? .granted : .unknown
        )
    }

    func beginCaptureFromHotkey() {
        guard isCaptureInProgress == false else {
            editorWindowController.showEditor()
            editorViewModel.noteCaptureAlreadyInProgress()
            return
        }

        Task { @MainActor [weak self] in
            await self?.requestAccessIfNeededAndBeginCapture()
        }
    }

    private func requestAccessIfNeededAndBeginCapture() async {
        if CGPreflightScreenCaptureAccess() {
            editorViewModel.updatePermissionState(.granted)
            editorViewModel.noteCaptureRequested()
            beginSelectionFlow()
            return
        }

        guard isPermissionRequestInProgress == false else {
            editorWindowController.showEditor()
            editorViewModel.updatePermissionState(.requesting)
            editorViewModel.notePermissionRequestPending()
            return
        }

        isPermissionRequestInProgress = true
        editorWindowController.showEditor()
        editorViewModel.updatePermissionState(.requesting)
        editorViewModel.notePermissionRequestPending()

        let granted = await Task.detached(priority: .userInitiated) {
            CGRequestScreenCaptureAccess()
        }.value

        isPermissionRequestInProgress = false

        guard granted else {
            editorViewModel.updatePermissionState(.denied)
            editorViewModel.notePermissionDenied()
            return
        }

        editorViewModel.updatePermissionState(.granted)
        editorViewModel.noteCaptureRequested()
        beginSelectionFlow()
    }

    private func beginSelectionFlow() {
        isCaptureInProgress = true
        editorViewModel.noteSelectionStarted()
        editorWindowController.closeEditor()

        selectionOverlayWindow.beginSelection { [weak self] result in
            guard let self else { return }

            switch result {
            case .cancelled:
                self.isCaptureInProgress = false
                self.editorWindowController.showEditor()
                self.editorViewModel.noteCaptureCancelled()
            case let .failed(message):
                self.isCaptureInProgress = false
                self.editorWindowController.showEditor()
                self.editorViewModel.noteCaptureFailure(message)
            case let .selected(rect):
                Task { @MainActor [weak self] in
                    await self?.captureSelection(in: rect)
                }
            }
        }
    }

    private func captureSelection(in rect: CGRect) async {
        editorViewModel.noteCaptureProcessing()

        do {
            try await Task.sleep(for: .milliseconds(120))
            let image = try await screenshotService.captureSelection(in: rect)
            isCaptureInProgress = false
            editorViewModel.presentCapture(image: image)
            editorWindowController.showEditor()
        } catch {
            isCaptureInProgress = false
            editorWindowController.showEditor()

            if screenshotService.looksLikePermissionFailure(error) {
                editorViewModel.updatePermissionState(.denied)
                editorViewModel.notePermissionDenied()
            } else {
                editorViewModel.noteCaptureFailure(error.localizedDescription)
            }
        }
    }
}
