import AppKit

final class ShottyAppDelegate: NSObject, NSApplicationDelegate {
    private var shottyApplication: ShottyApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSWindow.allowsAutomaticWindowTabbing = false

        let application = ShottyApplication()
        application.start()
        shottyApplication = application
    }

    func applicationWillTerminate(_ notification: Notification) {
        shottyApplication?.tearDown()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        shottyApplication?.reopenEditor()
        return true
    }
}
