import SwiftUI

public struct SidebarView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / Brand
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.accentTeal.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.accentTealBright)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("SentinelAI")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("macOS Sandbox Defense")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 22)
            
            Divider()
                .background(Theme.borderSubtle)
            
            // Navigation Items
            VStack(spacing: 4) {
                ForEach(SidebarTab.allCases) { tab in
                    Button(action: {
                        appState.selectedTab = tab
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 20)
                                .foregroundColor(appState.selectedTab == tab ? Theme.accentTealBright : Theme.textSecondary)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: appState.selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(appState.selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                            
                            Spacer()
                            
                            if tab == .analysis && SecurityEngine.shared.isAnalysisActive {
                                Circle()
                                    .fill(Theme.warningAmber)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(appState.selectedTab == tab ? Theme.surfaceElevated : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 14)
            
            Spacer()
            
            Divider()
                .background(Theme.borderSubtle)
            
            // Host Hardware & App Environment pill
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.prerequisites.isUTMInstalled ? Theme.accentTealBright : Theme.warningAmber)
                        .frame(width: 7, height: 7)
                    Text("Host: Apple Silicon (\(appState.prerequisites.architectureName))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                    Text(appState.prerequisites.isUTMInstalled ? "UTM Rilevato" : "UTM non rilevato")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
                
                Button(action: {
                    appState.showOnboardingModal = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                        Text("Limiti & Threat Model")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.accentTealBright)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(14)
        }
        .frame(minWidth: 200, maxWidth: 220)
        .background(Theme.bgSidebar)
    }
}
