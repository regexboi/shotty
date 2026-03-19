import AppKit
import Foundation

@MainActor
final class ExportService {
    enum ExportError: LocalizedError {
        case missingImage
        case renderFailed
        case pasteboardWriteFailed
        case pngEncodingFailed
        case invalidSaveDestination
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .missingImage:
                return "There is no captured image to export yet."
            case .renderFailed:
                return "Shotty could not flatten the annotated image."
            case .pasteboardWriteFailed:
                return "Shotty could not write the annotated image to the pasteboard."
            case .pngEncodingFailed:
                return "Shotty could not encode the annotated image as PNG."
            case .invalidSaveDestination:
                return "Shotty did not receive a valid save destination."
            case let .saveFailed(error):
                return "Shotty could not save the annotated image: \(error.localizedDescription)"
            }
        }
    }

    enum SaveOutcome {
        case cancelled
        case saved(URL)
    }

    func copyCurrentImage(document: EditorDocument) throws {
        let image = try renderedImage(for: document)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard pasteboard.writeObjects([image]) else {
            throw ExportError.pasteboardWriteFailed
        }
    }

    func saveCurrentImage(
        document: EditorDocument,
        from window: NSWindow?,
        completion: @escaping (Result<SaveOutcome, ExportError>) -> Void
    ) {
        do {
            let pngData = try pngData(for: document)
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = "Shotty Capture.png"

            if let window {
                panel.beginSheetModal(for: window) { response in
                    self.finishSavePanel(
                        response: response,
                        panel: panel,
                        pngData: pngData,
                        completion: completion
                    )
                }
            } else {
                let response = panel.runModal()
                finishSavePanel(
                    response: response,
                    panel: panel,
                    pngData: pngData,
                    completion: completion
                )
            }
        } catch let error as ExportError {
            completion(.failure(error))
        } catch {
            completion(.failure(.saveFailed(error)))
        }
    }

    private func finishSavePanel(
        response: NSApplication.ModalResponse,
        panel: NSSavePanel,
        pngData: Data,
        completion: @escaping (Result<SaveOutcome, ExportError>) -> Void
    ) {
        guard response == .OK else {
            completion(.success(.cancelled))
            return
        }

        guard let url = panel.url else {
            completion(.failure(.invalidSaveDestination))
            return
        }

        do {
            try pngData.write(to: url)
            completion(.success(.saved(url)))
        } catch {
            completion(.failure(.saveFailed(error)))
        }
    }

    private func pngData(for document: EditorDocument) throws -> Data {
        let image = try renderedImage(for: document)
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw ExportError.pngEncodingFailed
        }

        return pngData
    }

    private func renderedImage(for document: EditorDocument) throws -> NSImage {
        do {
            return try ScreenshotRenderer.renderedImage(for: document)
        } catch ScreenshotRenderer.RenderError.missingImage {
            throw ExportError.missingImage
        } catch ScreenshotRenderer.RenderError.renderFailed {
            throw ExportError.renderFailed
        } catch {
            throw ExportError.renderFailed
        }
    }
}
