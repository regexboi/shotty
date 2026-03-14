import AppKit
import Foundation

@MainActor
final class ExportService {
    func copyPlaceholder(document: EditorDocument) -> Bool {
        guard let image = document.capturedImage?.image else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    func showPlaceholderSavePanel(for document: EditorDocument, from window: NSWindow?) -> Bool {
        guard let image = document.capturedImage?.image else { return false }
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return false
        }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Shotty Capture.png"

        if let window {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                try? pngData.write(to: url)
            }
        } else {
            guard panel.runModal() == .OK, let url = panel.url else { return true }
            try? pngData.write(to: url)
        }

        return true
    }
}
