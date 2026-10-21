import SwiftUI

public struct SandboxView: View {
    @ObservedObject var appState: AppState
    @State private var showUTMWizard: Bool = false
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configurazione Sandbox")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Gestione guidata dell'ambiente isolato UTM e verifica prerequisiti.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            showUTMWizard = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                Text("Wizard Configurazione UTM")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.bgDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accentTealBright)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            appState.refreshEnvironment()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Riesamina")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.borderDefault, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Card 1: Prerequisiti Hardware & Host
                VStack(alignment: .leading, spacing: 14) {
                    Text("1. Prerequisiti Host macOS")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: appState.prerequisites.isAppleSilicon ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundColor(appState.prerequisites.isAppleSilicon ? Theme.accentTealBright : Theme.criticalRed)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Architettura Apple Silicon")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("Rilevata: \(appState.prerequisites.architectureName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            StatusBadgeView(appState.prerequisites.isAppleSilicon ? "Conforme" : "Incompatibile", style: appState.prerequisites.isAppleSilicon ? .verified : .critical)
                        }
                        .padding(10)
                        .background(Theme.surfaceElevated.opacity(0.4))
                        .cornerRadius(6)
                        
                        HStack {
                            Image(systemName: appState.prerequisites.isMacOSCompatible ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(appState.prerequisites.isMacOSCompatible ? Theme.accentTealBright : Theme.warningAmber)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Versione macOS")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("Rilevata: \(appState.prerequisites.macOSVersion) (Richiesto: macOS 14+)")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            StatusBadgeView(appState.prerequisites.isMacOSCompatible ? "Conforme" : "Attenzione", style: appState.prerequisites.isMacOSCompatible ? .verified : .manualReview)
                        }
                        .padding(10)
                        .background(Theme.surfaceElevated.opacity(0.4))
                        .cornerRadius(6)
                    }
                }
                .padding(16)
                .background(Theme.surfaceCard)
                .cornerRadius(Theme.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )
                
                // Card 2: Rilevamento UTM
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("2. Software di Virtualizzazione (UTM)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        StatusBadgeView(
                            appState.prerequisites.isUTMInstalled ? "Installato" : "Non trovato",
                            style: appState.prerequisites.isUTMInstalled ? .verified : .manualReview
                        )
                    }
                    
                    if appState.prerequisites.isUTMInstalled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UTM è presente sul sistema:")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Theme.accentTeal)
                                Text(appState.prerequisites.utmPath ?? "/Applications/UTM.app")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(8)
                            .background(Theme.bgDeep)
                            .cornerRadius(4)
                            
                            BannerAlertView(
                                title: "Nessuna installazione o modifica automatica",
                                message: "Come da specifica di sicurezza, SentinelAI non avvia download né modifica configurazioni senza consenso esplicito.",
                                level: .info
                            )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Per eseguire l'analisi dinamica in una macchina virtuale usa-e-getta, installa UTM dal canale ufficiale:")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack {
                                Text("Sito ufficiale: https://mac.getutm.app/")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.accentTealBright)
                                Spacer()
                                Button(action: {
                                    if let url = URL(string: "https://mac.getutm.app/") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Text("Apri sito UTM")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Theme.bgDeep)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Theme.accentTealBright)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(Theme.bgDeep)
                            .cornerRadius(6)
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
                
                // Card 3: Checklist di Isolamento Rigoroso
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("3. Configurazione Isolamento Rigoroso (UTM Guest)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Regole di isolamento prima di ogni analisi:")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        SecurityChecklistRow(
                            title: "Rete VM: Disconnessa di default",
                            detail: "Nessun bridge su ethernet/Wi-Fi e nessun accesso alla rete LAN locale.",
                            isVerified: appState.isolationChecklist.vmNetworkDisconnected
                        )
                        
                        SecurityChecklistRow(
                            title: "Condivisione directory: Disattivata",
                            detail: "Nessun filesystem dell'host (Cartelle, Desktop, Documenti) montato come WebDAV o VirtFS.",
                            isVerified: appState.isolationChecklist.hostFolderSharingDisabled
                        )
                        
                        SecurityChecklistRow(
                            title: "Appunti (Clipboard): Disattivati",
                            detail: "Nessun passaggio di testo o file tramite SPICE clipboard.",
                            isVerified: appState.isolationChecklist.sharedClipboardDisabled
                        )
                        
                        SecurityChecklistRow(
                            title: "Snapshot / Base Pulita Ripristinabile",
                            detail: "La VM deve avere uno snapshot di riferimento pulito per consentire il rollback immediato.",
                            isVerified: appState.isolationChecklist.cleanSnapshotVerified,
                            isManualCheckRequired: !appState.isolationChecklist.cleanSnapshotVerified,
                            toggleAction: {
                                appState.toggleManualVerificationForSnapshot()
                            }
                        )
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("VM Designata: \(appState.prerequisites.authorizedVMName)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Il controller invierà segnali di stop ESCLUSIVAMENTE a questa VM autorizzata.")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                        
                        Button(action: {
                            showUTMWizard = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                Text("Apri Wizard Hardening")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.accentTealBright)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accentTealSubtle)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                }
                .padding(16)
                .background(Theme.surfaceCard)
                .cornerRadius(Theme.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )
                
                // Card 4: Regola Non Negoziabile sulla Sospensione vs Bonifica
                BannerAlertView(
                    title: "Regola Non Negoziabile: Sospensione vs Bonifica",
                    message: UTMBonificaPolicy.suspensionCaveat,
                    level: .warning
                )
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
        .sheet(isPresented: $showUTMWizard) {
            UTMSetupWizardView(appState: appState)
        }
    }
}

