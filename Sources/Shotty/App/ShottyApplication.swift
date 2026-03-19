import AppKit

@MainActor
final class ShottyApplication {
    private let editorViewModel = EditorViewModel()
    private let statusItemController = ShottyStatusItemController()
    private lazy var editorWindowController = EditorWindowController(viewModel: editorViewModel)
    private lazy var screenshotService = ScreenshotService()
    private lazy var exportService = ExportService()
    private lazy var settingsStore = EditorSettingsStore()
    private lazy var captureCoordinator = CaptureCoordinator(
        editorViewModel: editorViewModel,
        editorWindowController: editorWindowController,
        screenshotService: screenshotService
    )
    private lazy var hotkeyManager = HotkeyManager()

    func start() {
        bindStatusItem()
        editorViewModel.bindExportService(exportService)
        editorViewModel.bindSettingsStore(settingsStore)
        captureCoordinator.prepareInitialExperience()

        do {
            try hotkeyManager.registerCaptureHotkey { [weak self] in
                Task { @MainActor [weak self] in
                    self?.captureCoordinator.beginCaptureFromHotkey()
                }
            }

            editorViewModel.noteHotkeyRegistrationSucceeded()
        } catch {
            editorViewModel.noteHotkeyRegistrationFailed(error.localizedDescription)
        }
    }

    func tearDown() {
        hotkeyManager.unregister()
    }

    func reopenEditor() {
        editorWindowController.showEditor()
    }

    func beginCapture() {
        captureCoordinator.beginCaptureFromHotkey()
    }

    private func bindStatusItem() {
        statusItemController.onOpenEditor = { [weak self] in
            self?.reopenEditor()
        }

        statusItemController.onCapture = { [weak self] in
            self?.beginCapture()
        }

        statusItemController.onQuit = {
            NSApp.terminate(nil)
        }
    }
}
