import SwiftUI

@main
struct ShottyApp: App {
    @NSApplicationDelegateAdaptor(ShottyAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
