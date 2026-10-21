import SwiftUI

public struct MainContentView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            SidebarView(appState: appState)
            
            Divider()
                .background(Theme.borderDefault)
            
            // Detail Screen
            ZStack {
                Theme.bgDeep.ignoresSafeArea()
                
                switch appState.selectedTab {
                case .overview:
                    OverviewView(appState: appState)
                case .sandbox:
                    SandboxView(appState: appState)
                case .analysis:
                    AnalysisView(appState: appState)
                case .events:
                    EventsView(appState: appState)
                case .settings:
                    SettingsView(appState: appState)
                }
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .sheet(isPresented: $appState.showOnboardingModal) {
            OnboardingModalView(appState: appState)
        }
    }
}
