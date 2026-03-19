import Foundation

struct EditorSettingsStore {
    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        fileURL = baseDirectory
            .appendingPathComponent("Shotty", isDirectory: true)
            .appendingPathComponent("editor-settings.json", isDirectory: false)
    }

    func load() throws -> PersistedEditorSettings? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(PersistedEditorSettings.self, from: data)
    }

    func save(_ settings: PersistedEditorSettings) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(settings)
        try data.write(to: fileURL, options: .atomic)
    }

    var settingsFileURL: URL {
        fileURL
    }
}

struct PersistedEditorSettings: Codable {
    let selectedTool: AnnotationTool
    let appearance: PersistedScreenshotAppearance
    let toolStyles: [String: PersistedAnnotationToolStyle]
}

struct PersistedScreenshotAppearance: Codable {
    let backgroundModeEnabled: Bool
    let backgroundPreset: ScreenshotBackgroundPreset
    let padding: Double
    let inset: Double
    let cornerRadius: Double
    let shadow: Double
    let balanceEnabled: Bool

    init(appearance: ScreenshotAppearance) {
        backgroundModeEnabled = appearance.backgroundModeEnabled
        backgroundPreset = appearance.backgroundPreset
        padding = Double(appearance.padding)
        inset = Double(appearance.inset)
        cornerRadius = Double(appearance.cornerRadius)
        shadow = Double(appearance.shadow)
        balanceEnabled = appearance.balanceEnabled
    }

    var screenshotAppearance: ScreenshotAppearance {
        ScreenshotAppearance(
            backgroundModeEnabled: backgroundModeEnabled,
            backgroundPreset: backgroundPreset,
            padding: CGFloat(padding),
            inset: CGFloat(inset),
            cornerRadius: CGFloat(cornerRadius),
            shadow: CGFloat(shadow),
            balanceEnabled: balanceEnabled
        )
    }
}

struct PersistedAnnotationToolStyle: Codable {
    let colorToken: AnnotationColorToken
    let sizePreset: AnnotationSizePreset

    init(style: AnnotationToolStyle) {
        colorToken = style.colorToken
        sizePreset = style.sizePreset
    }

    var annotationToolStyle: AnnotationToolStyle {
        AnnotationToolStyle(
            colorToken: colorToken,
            sizePreset: sizePreset
        )
    }
}
