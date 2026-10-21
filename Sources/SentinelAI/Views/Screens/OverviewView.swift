import SwiftUI

public struct OverviewView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Panoramica")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Stato operativo dell'host e configurazione della sandbox di contenimento.")
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
                    title: "Prototipo di Sicurezza SentinelAI v0.1",
                    message: "SentinelAI isola i file sospetti in una VM dedicata per limitare la superficie d'attacco. Non sostituisce XProtect, Gatekeeper o il firewall di macOS.",
                    level: .info
                )
                
                // Top Metric Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    // Card 1: Sandbox UTM
                    MetricCardView(
                        title: "Sandbox UTM",
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
                        title: "Motore di Rilevamento",
                        value: "\(appState.ruleCount) Regole Attive",
                        detail: "Versione: \(appState.ruleEngineVersion). Motore deterministico indipendente da LLM.",
                        icon: "bolt.shield.fill",
                        badgeText: "Deterministico",
                        badgeStyle: .verified
                    )
                    
                    // Card 3: Analista AI
                    MetricCardView(
                        title: "Analista AI Locale",
                        value: "Non Configurato",
                        detail: "Funzionalità opzionale (Ollama) pianificata per v0.6. Nessun invio dati al cloud.",
                        icon: "brain.head.profile",
                        badgeText: "Opzionale v0.6",
                        badgeStyle: .notConfigured
                    )
                }
                
                // Controlli di Sicurezza / Checklist Isolamento
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Controlli di Isolamento Host/Guest")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Text("Policy Fail-Closed Attiva")
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
                        Text("Attività Recenti")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        
                        Button(action: {
                            appState.selectedTab = .analysis
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Avvia nuova analisi")
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
                            Text("Nessuna analisi eseguita")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                            Text("Seleziona un file da verificare in modalità isolata per avviare il preflight.")
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
    }
}
