import SwiftUI
import RealityKit
import RealityKitContent

@main
struct OpenClawControlVisionApp: App {
    var body: some Scene {
        WindowGroup {
            VisionMainView()
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
    }
}
