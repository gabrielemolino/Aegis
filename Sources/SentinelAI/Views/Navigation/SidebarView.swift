import SwiftUI

public struct SidebarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var i18n = LocalizationManager.shared
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header / Brand Aegis
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
                    Text(i18n.t("app_name"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(i18n.t("app_subtitle"))
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
                            
                            Text(tab.localizedName)
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
                    Text("\(i18n.t("sidebar_host_silicon")) (\(appState.prerequisites.architectureName))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                    Text(appState.prerequisites.isUTMInstalled ? i18n.t("sidebar_utm_detected") : i18n.t("sidebar_utm_missing"))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
                
                Button(action: {
                    appState.showOnboardingModal = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                        Text(i18n.t("sidebar_limits_threat_model"))
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
