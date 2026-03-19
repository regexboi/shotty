import AppKit
import SwiftUI

@MainActor
final class EditorWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: EditorViewModel

    init(viewModel: EditorViewModel) {
        self.viewModel = viewModel
        let window = EditorPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        window.center()
        window.delegate = self
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.isReleasedWhenClosed = false

        let rootView = EditorRootView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.cornerRadius = 32
        hostingController.view.layer?.masksToBounds = false
        window.contentViewController = hostingController
        window.setFrameAutosaveName("ShottyEditorWindow")

        viewModel.windowProvider = self
        viewModel.onRequestClose = { [weak self] in
            self?.closeEditor()
        }

        window.onEscape = { [weak self] in
            self?.viewModel.handleEscape()
        }
        window.onDelete = { [weak self] in
            self?.viewModel.deleteSelectedAnnotation()
        }
        window.onUndo = { [weak self] in
            self?.viewModel.undo()
        }
        window.onRedo = { [weak self] in
            self?.viewModel.redo()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showEditor() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeEditor() {
        window?.orderOut(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window?.orderOut(nil)
    }
}

private final class EditorPanel: NSPanel {
    var onEscape: (() -> Void)?
    var onDelete: (() -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func keyDown(with event: NSEvent) {
        if shouldHandleEditorShortcutLocally,
           event.modifierFlags.intersection(.deviceIndependentFlagsMask).isDisjoint(with: [.command, .shift, .option, .control]),
           event.keyCode == 51 || event.keyCode == 117 {
            onDelete?()
            return
        }

        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard shouldHandleEditorShortcutLocally else {
            return super.performKeyEquivalent(with: event)
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let characters = event.charactersIgnoringModifiers?.lowercased()

        if characters == "z", flags == [.command] {
            onUndo?()
            return true
        }

        if characters == "z", flags == [.command, .shift] {
            onRedo?()
            return true
        }

        return super.performKeyEquivalent(with: event)
    }

    private var shouldHandleEditorShortcutLocally: Bool {
        (firstResponder is NSTextView) == false
    }
}
