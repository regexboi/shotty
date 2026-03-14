import AppKit

@MainActor
final class SelectionOverlayWindow {
    private(set) var isPresentingSelectionUI = false

    func beginPlaceholderSelection() {
        isPresentingSelectionUI = true
    }

    func cancel() {
        isPresentingSelectionUI = false
    }
}
