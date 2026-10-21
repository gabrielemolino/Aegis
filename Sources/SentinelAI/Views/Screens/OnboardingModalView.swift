import SwiftUI

public struct OnboardingModalView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var i18n = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var acceptedDisclaimer: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Theme.accentTealBright)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(i18n.t("onboarding_welcome"))
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(i18n.t("onboarding_version_title"))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                
                Button(action: {
                    completeOnboarding()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Theme.surfaceElevated)
            
            Divider().background(Theme.borderSubtle)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Language Setup Card
                    languageSelectionCard
                    
                    // 2. Legal Disclaimer / Limitation of Liability Card
                    liabilityDisclaimerCard
                    
                    // 3. Defense Posture & Scope
                    scopeSection
                    
                    // 4. Non-Negotiable Project Principles
                    principlesSection
                    
                    // 5. Host Prerequisites Summary
                    prerequisitesSection
                }
                .padding(20)
            }
            
            Divider().background(Theme.borderSubtle)
            
            // Footer
            HStack {
                Text(i18n.t("disclaimer_badge"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.warningAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.warningAmber.opacity(0.15))
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: {
                    completeOnboarding()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                        Text(i18n.t("disclaimer_button_accept"))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bgDeep)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(acceptedDisclaimer ? Theme.accentTealBright : Theme.textMuted)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!acceptedDisclaimer)
            }
            .padding(16)
            .background(Theme.surfaceElevated)
        }
        .frame(width: 620, height: 620)
        .background(Theme.bgDeep)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var languageSelectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Theme.accentTeal)
                Text(i18n.t("onboarding_language_prompt"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: {
                        i18n.setLanguage(lang)
                    }) {
                        HStack(spacing: 8) {
                            Text(lang.flag)
                                .font(.system(size: 16))
                            Text(lang.displayName)
                                .font(.system(size: 12, weight: i18n.currentLanguage == lang ? .bold : .medium))
                                .foregroundColor(i18n.currentLanguage == lang ? Theme.accentTealBright : Theme.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(i18n.currentLanguage == lang ? Theme.accentTealSubtle : Theme.surfaceElevated)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(i18n.currentLanguage == lang ? Theme.accentTeal : Theme.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(Theme.surfaceCard)
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.borderDefault, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var liabilityDisclaimerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.warningAmber)
                Text(i18n.t("disclaimer_title"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                StatusBadgeView(i18n.t("disclaimer_badge"), style: .manualReview)
            }
            
            Text(i18n.t("disclaimer_summary"))
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
                .padding(10)
                .background(Theme.bgDeep)
                .cornerRadius(6)
            
            Toggle(isOn: $acceptedDisclaimer) {
                Text(i18n.t("disclaimer_checkbox"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentTealBright)
            }
            .toggleStyle(.checkbox)
            .padding(.top, 4)
        }
        .padding(14)
        .background(Theme.warningAmber.opacity(0.06))
        .cornerRadius(Theme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.warningAmber.opacity(0.35), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(i18n.t("onboarding_scope_title"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            Text(i18n.t("onboarding_scope_desc"))
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            
            BannerAlertView(
                title: i18n.t("onboarding_not_promised_title"),
                message: i18n.t("onboarding_not_promised_msg"),
                level: .warning
            )
        }
    }
    
    @ViewBuilder
    private var principlesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(i18n.t("onboarding_principles_title"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            VStack(alignment: .leading, spacing: 6) {
                bulletPoint(i18n.t("onboarding_rule_1"))
                bulletPoint(i18n.t("onboarding_rule_2"))
                bulletPoint(i18n.t("onboarding_rule_3"))
                bulletPoint(i18n.t("onboarding_rule_4"))
                bulletPoint(i18n.t("onboarding_rule_5"))
                bulletPoint(i18n.t("onboarding_rule_6"))
            }
        }
    }
    
    @ViewBuilder
    private var prerequisitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stato Prerequisiti Host / Host Environment:")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            HStack(spacing: 10) {
                StatusBadgeView("Apple Silicon: \(appState.prerequisites.architectureName)", style: appState.prerequisites.isAppleSilicon ? .verified : .critical)
                StatusBadgeView(appState.prerequisites.macOSVersion, style: appState.prerequisites.isMacOSCompatible ? .verified : .manualReview)
                StatusBadgeView(appState.prerequisites.isUTMInstalled ? i18n.t("sidebar_utm_detected") : i18n.t("sidebar_utm_missing"), style: appState.prerequisites.isUTMInstalled ? .verified : .manualReview)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "aegis_onboarding_completed")
        appState.showOnboardingModal = false
        dismiss()
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Theme.accentTeal)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

