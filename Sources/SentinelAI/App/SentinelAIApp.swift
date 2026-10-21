import SwiftUI

@main
public struct SentinelAIApp: App {
    @StateObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup("Aegis — macOS Sandbox Defense") {
            MainContentView(appState: appState)
                .preferredColorScheme(.dark)
                .background(Theme.bgDeep)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands()
        }
    }
}
