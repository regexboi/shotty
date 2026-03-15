import AppKit

@MainActor
final class ShottyStatusItemController: NSObject {
    var onOpenEditor: (() -> Void)?
    var onCapture: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    override init() {
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Shotty")
            button.imagePosition = .imageOnly
            button.toolTip = "Shotty"
        }

        let openEditorItem = NSMenuItem(
            title: "Open Editor",
            action: #selector(handleOpenEditor),
            keyEquivalent: ""
        )
        openEditorItem.target = self
        menu.addItem(openEditorItem)

        let captureItem = NSMenuItem(
            title: "Capture Area",
            action: #selector(handleCapture),
            keyEquivalent: ""
        )
        captureItem.target = self
        menu.addItem(captureItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Shotty",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc
    private func handleOpenEditor() {
        onOpenEditor?()
    }

    @objc
    private func handleCapture() {
        onCapture?()
    }

    @objc
    private func handleQuit() {
        onQuit?()
    }
}
