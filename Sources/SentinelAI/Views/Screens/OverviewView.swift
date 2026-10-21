import SwiftUI

public struct OverviewView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var llmService = LocalLLMService.shared
    @ObservedObject private var i18n = LocalizationManager.shared
    @State private var showRuleCatalogModal: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(i18n.t("overview_title"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(i18n.t("overview_subtitle"))
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Overall status badge - strictly adheres to spec
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appState.overallProtectionStatus == .fullyProtected ? Theme.accentTealBright : Theme.warningAmber)
                            .frame(width: 9, height: 9)
                        
                        Text(appState.overallProtectionStatus.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(appState.overallProtectionStatus == .fullyProtected ? Theme.accentTealBright : Theme.warningAmber)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(appState.overallProtectionStatus == .fullyProtected ? Theme.accentTealSubtle : Theme.warningAmberSubtle)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(appState.overallProtectionStatus == .fullyProtected ? Theme.accentTeal.opacity(0.3) : Theme.warningAmber.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Prototype notice banner
                BannerAlertView(
                    title: i18n.t("overview_banner_title"),
                    message: i18n.t("overview_banner_desc"),
                    level: .info
                )
                
                // Top Metric Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    // Card 1: Sandbox UTM
                    MetricCardView(
                        title: i18n.t("overview_card_utm_title"),
                        value: appState.vmStatus.rawValue,
                        detail: appState.prerequisites.isUTMInstalled ? "Applicazione UTM rilevata. Richiesta verifica snapshot." : "UTM non trovato nel percorso predefinito.",
                        icon: "shippingbox.fill",
                        badgeText: appState.vmStatus == .verified ? "Pronta" : "Da verificare",
                        badgeStyle: appState.vmStatus == .verified ? .verified : .manualReview,
                        actionTitle: "Configura ambiente →",
                        action: {
                            appState.selectedTab = .sandbox
                        }
                    )
                    
                    // Card 2: Motore Regole
                    MetricCardView(
                        title: i18n.t("overview_card_rules_title"),
                        value: "\(RuleEngineService.shared.rulesCatalog.count) Regole Versionate",
                        detail: "Versione: \(RuleEngineService.shared.engineVersion). Valutazione deterministica su eventi fixture.",
                        icon: "bolt.shield.fill",
                        badgeText: "Deterministico",
                        badgeStyle: .verified,
                        actionTitle: i18n.t("overview_explore_rules"),
                        action: {
                            showRuleCatalogModal = true
                        }
                    )
                    
                    // Card 3: Analista AI Locale
                    llmCardView
                }
                
                // Controlli di Sicurezza / Checklist Isolamento
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(i18n.t("overview_checklist_title"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Text(i18n.t("overview_fail_closed_active"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                    }
                    
                    VStack(spacing: 8) {
                        SecurityChecklistRow(
                            title: "Condivisione cartelle host",
                            detail: "Nessun volume host montato o condiviso nella macchina virtuale.",
                            isVerified: appState.isolationChecklist.hostFolderSharingDisabled
                        )
                        
                        SecurityChecklistRow(
                            title: "Appunti condivisi (Clipboard)",
                            detail: "Sincronizzazione clipboard host/guest disabilitata.",
                            isVerified: appState.isolationChecklist.sharedClipboardDisabled
                        )
                        
                        SecurityChecklistRow(
                            title: "Rete della VM",
                            detail: "Nessun bridge su interfaccia LAN; disconnessione attiva di default.",
                            isVerified: appState.isolationChecklist.vmNetworkDisconnected
                        )
                        
                        SecurityChecklistRow(
                            title: "Stato snapshot / Base pulita",
                            detail: "La VM deve essere ripristinabile prima e dopo ogni sessione di analisi.",
                            isVerified: appState.isolationChecklist.cleanSnapshotVerified,
                            isManualCheckRequired: !appState.isolationChecklist.cleanSnapshotVerified,
                            toggleAction: {
                                appState.toggleManualVerificationForSnapshot()
                            }
                        )
                    }
                }
                .padding(16)
                .background(Theme.surfaceCard)
                .cornerRadius(Theme.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )
                
                // Sezione Attività Recenti
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(i18n.t("overview_recent_activity"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        
                        Button(action: {
                            appState.selectedTab = .analysis
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text(i18n.t("overview_start_new_analysis"))
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.accentTealBright)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accentTealSubtle)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if appState.recentAnalyses.isEmpty {
                        // Stato vuoto richiesto dalla specifica
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 30))
                                .foregroundColor(Theme.textMuted)
                            Text(i18n.t("overview_no_analyses"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                            Text(i18n.t("overview_no_analyses_sub"))
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 34)
                        .background(Theme.surfaceElevated.opacity(0.3))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.borderSubtle, lineWidth: 1)
                        )
                    } else {
                        // Lista report recenti
                        VStack(spacing: 8) {
                            ForEach(appState.recentAnalyses) { report in
                                HStack(spacing: 12) {
                                    Image(systemName: report.classification.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(report.classification == .detected ? Theme.criticalRed : (report.classification == .suspicious ? Theme.warningAmber : Theme.accentTealBright))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(report.targetFile.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.textPrimary)
                                        HStack(spacing: 8) {
                                            Text(report.targetFile.formattedSize)
                                            Text("•")
                                            Text("SHA256: \(report.targetFile.sha256.prefix(12))...")
                                            if report.isSimulatedDemo {
                                                Text("• [Dati Demo Simulati]")
                                                    .foregroundColor(Theme.warningAmber)
                                            }
                                        }
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    StatusBadgeView(
                                        report.classification.rawValue,
                                        style: .classification(report.classification)
                                    )
                                }
                                .padding(12)
                                .background(Theme.surfaceElevated.opacity(0.5))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Theme.surfaceCard)
                .cornerRadius(Theme.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
        .sheet(isPresented: $showRuleCatalogModal) {
            RuleCatalogView(appState: appState)
        }
    }
    
    // MARK: - Card 3: Analista AI Locale
    
    @ViewBuilder
    private var llmCardView: some View {
        let isReady = llmService.status == .ready
        let isMock = llmService.config.isMockFallbackEnabled
        let badgeText = isReady ? "Online" : (isMock ? "Mock v0.6" : "Offline")
        let badgeStyle: StatusBadgeView.BadgeStyle = isReady ? .verified : (isMock ? .manualReview : .notConfigured)
        
        let detailText: String = {
            if isReady {
                return "Ollama attivo su :11434. Triage semantico locale e mapping MITRE ATT&CK."
            } else if isMock {
                return "Simulatore semantico v0.6 attivo per test e validazione schema JSON."
            } else {
                return "Ollama non attivo. Il motore deterministico garantisce la protezione."
            }
        }()
        
        MetricCardView(
            title: i18n.t("overview_card_llm_title"),
            value: llmService.config.selectedModel,
            detail: detailText,
            icon: "brain.head.profile",
            badgeText: badgeText,
            badgeStyle: badgeStyle,
            actionTitle: i18n.t("overview_configure_model"),
            action: {
                appState.selectedTab = .settings
            }
        )
    }
}

