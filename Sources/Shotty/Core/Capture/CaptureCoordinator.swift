import CoreGraphics
import Dispatch
import Foundation

@MainActor
final class CaptureCoordinator {
    enum PermissionState: Equatable {
        case unknown
        case requesting
        case granted
        case denied
    }

    private enum Constants {
        static let permissionPromptedKey = "shotty.screenCapturePermissionPrompted"
    }

    private let editorViewModel: EditorViewModel
    private let editorWindowController: EditorWindowController
    private let screenshotService: ScreenshotService
    private let selectionOverlayWindow = SelectionOverlayWindow()
    private let userDefaults: UserDefaults
    private var isCaptureInProgress = false

    init(
        editorViewModel: EditorViewModel,
        editorWindowController: EditorWindowController,
        screenshotService: ScreenshotService,
        userDefaults: UserDefaults = .standard
    ) {
        self.editorViewModel = editorViewModel
        self.editorWindowController = editorWindowController
        self.screenshotService = screenshotService
        self.userDefaults = userDefaults
    }

    func prepareInitialExperience() {
        editorWindowController.showEditor()
        editorViewModel.loadInitialState(permissionState: currentPermissionState())
    }

    func beginCaptureFromHotkey() {
        guard isCaptureInProgress == false else {
            editorWindowController.showEditor()
            editorViewModel.noteCaptureAlreadyInProgress()
            return
        }

        editorViewModel.noteCaptureRequested()

        switch currentPermissionState() {
        case .granted:
            beginSelectionFlow()
        case .unknown:
            requestScreenCapturePermission()
        case .requesting:
            editorWindowController.showEditor()
            editorViewModel.updatePermissionState(.requesting)
            editorViewModel.notePermissionRequestPending()
        case .denied:
            editorWindowController.showEditor()
            editorViewModel.updatePermissionState(.denied)
            editorViewModel.notePermissionDenied()
        }
    }

    private func currentPermissionState() -> PermissionState {
        if editorViewModel.permissionState == .requesting {
            return .requesting
        }

        if CGPreflightScreenCaptureAccess() {
            return .granted
        }

        return userDefaults.bool(forKey: Constants.permissionPromptedKey) ? .denied : .unknown
    }

    private func requestScreenCapturePermission() {
        editorWindowController.showEditor()
        editorViewModel.updatePermissionState(.requesting)
        editorViewModel.notePermissionRequestPending()
        userDefaults.set(true, forKey: Constants.permissionPromptedKey)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let granted = CGRequestScreenCaptureAccess()

            DispatchQueue.main.async {
                guard let self else { return }

                let nextState: PermissionState = granted ? .granted : .denied
                self.editorViewModel.updatePermissionState(nextState)

                if granted {
                    self.beginSelectionFlow()
                } else {
                    self.editorWindowController.showEditor()
                    self.editorViewModel.notePermissionDenied()
                }
            }
        }
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

            if CGPreflightScreenCaptureAccess() == false {
                editorViewModel.updatePermissionState(.denied)
                editorViewModel.notePermissionDenied()
            } else {
                editorViewModel.noteCaptureFailure(error.localizedDescription)
            }
        }
    }
}
