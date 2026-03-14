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
        editorWindowController.showEditor()
        editorViewModel.noteCaptureRequested()

        switch currentPermissionState() {
        case .granted:
            selectionOverlayWindow.beginPlaceholderSelection()
            let placeholderImage = screenshotService.makePlaceholderImage()
            editorViewModel.presentCapturePlaceholder(image: placeholderImage)
        case .unknown:
            requestScreenCapturePermission()
        case .requesting:
            editorViewModel.updatePermissionState(.requesting)
            editorViewModel.notePermissionRequestPending()
        case .denied:
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
                    self.selectionOverlayWindow.beginPlaceholderSelection()
                    let placeholderImage = self.screenshotService.makePlaceholderImage()
                    self.editorViewModel.presentCapturePlaceholder(image: placeholderImage)
                } else {
                    self.editorViewModel.notePermissionDenied()
                }
            }
        }
    }
}
