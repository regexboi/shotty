import AppKit

@MainActor
final class ShottyApplication {
    private let editorViewModel = EditorViewModel()
    private lazy var editorWindowController = EditorWindowController(viewModel: editorViewModel)
    private lazy var screenshotService = ScreenshotService()
    private lazy var exportService = ExportService()
    private lazy var captureCoordinator = CaptureCoordinator(
        editorViewModel: editorViewModel,
        editorWindowController: editorWindowController,
        screenshotService: screenshotService
    )
    private lazy var hotkeyManager = HotkeyManager()

    func start() {
        editorViewModel.bindExportService(exportService)
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
}
