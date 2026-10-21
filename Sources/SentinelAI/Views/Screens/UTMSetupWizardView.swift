import SwiftUI
import AppKit

public struct UTMSetupWizardView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: Int = 1
    @State private var vmConfig: UTMVMConfig
    @State private var nameValidationMessage: String? = nil
    @State private var isProbingLiveStatus: Bool = false
    @State private var liveStatusResult: String? = nil
    
    private let utmService = UTMManagementService.shared
    private let auditLogger = AuditLogger.shared
    
    public init(appState: AppState) {
        self.appState = appState
        _vmConfig = State(initialValue: utmService.loadConfiguration())
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header con indicatore step
            wizardHeader
            
            Divider().background(Theme.borderSubtle)
            
            // Corpo centrale variabile a seconda dello step
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch currentStep {
                    case 1:
                        step1SoftwarePrerequisites
                    case 2:
                        step2VMCreation
                    case 3:
                        step3HardeningChecklist
                    case 4:
                        step4CleanSnapshotPolicy
                    case 5:
                        step5FinalSummary
                    default:
                        EmptyView()
                    }
                }
                .padding(24)
            }
            
            Divider().background(Theme.borderSubtle)
            
            // Footer con navigazione Indietro / Avanti / Salva
            wizardFooter
        }
        .frame(width: 680, height: 600)
        .background(Theme.bgDeep)
    }
    
    // MARK: - Header
    private var wizardHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.accentTeal.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.accentTealBright)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Configurazione Guidata Sandbox UTM (v0.2)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("Passo \(currentStep) di 5 — Definizione, Isolamento e Snapshot della VM")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Theme.surfaceElevated)
    }
    
    // MARK: - Step 1: Verifica Software UTM
    private var step1SoftwarePrerequisites: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Passo 1: Verifica del Software di Virtualizzazione")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            Text("SentinelAI richiede l'hypervisor open-source UTM per eseguire l'analisi in una macchina virtuale usa-e-getta separata dall'host macOS.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                Image(systemName: appState.prerequisites.isUTMInstalled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(appState.prerequisites.isUTMInstalled ? Theme.accentTealBright : Theme.warningAmber)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.prerequisites.isUTMInstalled ? "UTM Rilevato nel Sistema" : "UTM Non Trovato in /Applications/UTM.app")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(appState.prerequisites.utmPath ?? "Nessun percorso applicativo trovato")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
                StatusBadgeView(appState.prerequisites.isUTMInstalled ? "Installato" : "Non presente", style: appState.prerequisites.isUTMInstalled ? .verified : .manualReview)
            }
            .padding(12)
            .background(Theme.surfaceCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderDefault, lineWidth: 1))
            
            if !appState.prerequisites.isUTMInstalled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Istruzioni per l'installazione:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("1. Scarica UTM dal sito ufficiale https://mac.getutm.app/\n2. Trascina UTM.app nella cartella /Applications/\n3. Torna qui e premi 'Riesamina'.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                    
                    Button(action: {
                        if let url = URL(string: "https://mac.getutm.app/") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Apri Sito Ufficiale UTM →")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.bgDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accentTealBright)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            } else {
                BannerAlertView(
                    title: "Principio di Minimo Privilegio",
                    message: "SentinelAI non esegue comandi con 'sudo' e non altera il sistema operativo host. L'ambiente isolato opera in spazio utente tramite UTM.",
                    level: .info
                )
            }
        }
    }
    
    // MARK: - Step 2: Definizione VM Ubuntu ARM64
    private var step2VMCreation: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Passo 2: Configurazione della Macchina Virtuale Dedicata")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            Text("Per ragioni di contenimento, il controller host interagisce ESCLUSIVAMENTE con la VM designata per i test. È severamente vietato interagire con macchine virtuali arbitrarie.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Identificatore VM Autorizzata (Nome in UTM):")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                TextField("Nome VM (es. SentinelAI-Ubuntu-Guest)", text: $vmConfig.vmName)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(6)
                    .foregroundColor(Theme.textPrimary)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(nameValidationMessage != nil ? Theme.criticalRed : Theme.borderDefault, lineWidth: 1))
                    .onChange(of: vmConfig.vmName) { _, newValue in
                        let val = utmService.validateVMName(newValue)
                        nameValidationMessage = val.errorReason
                    }
                
                if let err = nameValidationMessage {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.criticalRed)
                } else {
                    Text("Consentiti solo caratteri alfanumerici, trattini e underscore (max 64 caratteri).")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .padding(12)
            .background(Theme.surfaceCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderDefault, lineWidth: 1))
            
            // Verifica live di stato non bloccante
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Verifica Presenza in UTM (Query utmctl sicura)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    if isProbingLiveStatus {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Button(action: {
                            probeLiveVMStatus()
                        }) {
                            Text("Interroga Stato →")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.accentTealBright)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let status = liveStatusResult {
                    Text(status)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.bgDeep)
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .background(Theme.surfaceCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderDefault, lineWidth: 1))
        }
    }
    
    // MARK: - Step 3: Checklist di Hardening (Isolamento Rigoroso)
    private var step3HardeningChecklist: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Passo 3: Checklist di Indurimento e Isolamento Rigoroso")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            Text("Prima di avviare analisi, imposta i parametri della VM in UTM esattamente come indicato di seguito:")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            VStack(spacing: 10) {
                hardeningToggleRow(
                    title: "1. Rete Disconnessa (Network Mode: None)",
                    description: "Disabilita la scheda di rete nelle impostazioni UTM della VM. Nessuna connessione NAT o bridged consentita per evitare worm e connessioni C2.",
                    isOn: $vmConfig.isNetworkIsolated
                )
                
                hardeningToggleRow(
                    title: "2. Nessuna Cartella Condivisa (Shared Directory: None)",
                    description: "Rimuovi qualsiasi condivisione SPICE / VirtFS / WebDAV con l'host macOS per impedire al campione di leggere o sovrascrivere documenti personali.",
                    isOn: $vmConfig.isFolderSharingDisabled
                )
                
                hardeningToggleRow(
                    title: "3. Appunti Condivisi Disabilitati (Clipboard: Disabled)",
                    description: "Disattiva la sincronizzazione degli appunti SPICE per evitare transito involontario di payload o credenziali tra host e guest.",
                    isOn: $vmConfig.isClipboardSharingDisabled
                )
                
                hardeningToggleRow(
                    title: "4. USB Passthrough Disabilitato",
                    description: "Rimuovi qualsiasi periferica USB collegata alla macchina virtuale per ridurre la superficie di breakout hardware.",
                    isOn: $vmConfig.isUsbPassthroughDisabled
                )
            }
        }
    }
    
    // MARK: - Step 4: Snapshot Pulito e Policy Bonifica
    private var step4CleanSnapshotPolicy: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Passo 4: Creazione della Base Pulita (Snapshot 'clean-baseline')")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            BannerAlertView(
                title: "Principio Chiave sulla Sospensione (Pause/Suspend)",
                message: UTMBonificaPolicy.suspensionCaveat,
                level: .warning
            )
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Procedura per creare lo snapshot in UTM:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("1. Avvia la VM Ubuntu pulita e installa gli aggiornamenti base.\n2. Spegni la VM in modo ordinato (stato: Stopped).\n3. In UTM, seleziona la VM > scheda 'Snapshots' (o clona come Golden Master).\n4. Salva uno snapshot denominato 'clean-baseline'.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                
                Divider().background(Theme.borderSubtle)
                
                Toggle(isOn: $vmConfig.hasCleanSnapshot) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confermo la presenza dello snapshot 'clean-baseline' ripristinabile")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Questa attestazione abilita il superamento del preflight in conformità alla policy.")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .toggleStyle(.checkbox)
            }
            .padding(14)
            .background(Theme.surfaceCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderDefault, lineWidth: 1))
        }
    }
    
    // MARK: - Step 5: Riepilogo e Salvataggio
    private var step5FinalSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Passo 5: Riepilogo Conformità e Attivazione Sandbox")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.accentTealBright)
            
            let compliance = vmConfig.complianceScore
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Punteggio di Indurimento:")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(compliance.passed) di \(compliance.total) requisiti soddisfatti")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(vmConfig.isFullyHardened ? Theme.accentTealBright : Theme.warningAmber)
                }
                Spacer()
                StatusBadgeView(vmConfig.isFullyHardened ? "Configurazione Conforme" : "Verifica Incompleta", style: vmConfig.isFullyHardened ? .verified : .manualReview)
            }
            .padding(14)
            .background(Theme.surfaceCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderDefault, lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Dettaglio parametri registrati:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                summaryRow("VM Autorizzata", value: vmConfig.vmName)
                summaryRow("Isolamento Rete", value: vmConfig.isNetworkIsolated ? "Disconnessa (OK)" : "NON ISOLATA")
                summaryRow("Condivisione Cartelle", value: vmConfig.isFolderSharingDisabled ? "Disattivata (OK)" : "ATTIVA (RISCHIO)")
                summaryRow("Clipboard Condivisa", value: vmConfig.isClipboardSharingDisabled ? "Disattivata (OK)" : "ATTIVA (RISCHIO)")
                summaryRow("USB Passthrough", value: vmConfig.isUsbPassthroughDisabled ? "Disattivato (OK)" : "ATTIVO (RISCHIO)")
                summaryRow("Snapshot Baseline", value: vmConfig.hasCleanSnapshot ? "clean-baseline (Verificato)" : "NON VERIFICATO")
            }
            .padding(14)
            .background(Theme.surfaceCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderDefault, lineWidth: 1))
            
            if !vmConfig.isFullyHardened {
                BannerAlertView(
                    title: "Policy Fail-Closed Attiva",
                    message: "Tutti i 5 criteri devono essere conformi per abilitare l'avvio delle analisi senza blocchi.",
                    level: .warning
                )
            }
        }
    }
    
    // MARK: - Footer
    private var wizardFooter: some View {
        HStack {
            if currentStep > 1 {
                Button(action: { currentStep -= 1 }) {
                    Text("← Indietro")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            if currentStep < 5 {
                Button(action: {
                    if currentStep == 2 {
                        let val = utmService.validateVMName(vmConfig.vmName)
                        if !val.isValid {
                            nameValidationMessage = val.errorReason
                            return
                        }
                    }
                    currentStep += 1
                }) {
                    Text("Continua →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.bgDeep)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Theme.accentTealBright)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    commitConfiguration()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Salva e Attiva Configurazione Sandbox")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bgDeep)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(vmConfig.isFullyHardened ? Theme.accentTealBright : Theme.warningAmber)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Theme.surfaceElevated)
    }
    
    // MARK: - Helper Views & Actions
    private func hardeningToggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .toggleStyle(.switch)
        .padding(10)
        .background(Theme.surfaceCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderDefault, lineWidth: 1))
    }
    
    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
        }
    }
    
    private func probeLiveVMStatus() {
        isProbingLiveStatus = true
        liveStatusResult = nil
        Task {
            let res = await utmService.queryVMStatus(vmName: vmConfig.vmName)
            await MainActor.run {
                self.isProbingLiveStatus = false
                self.liveStatusResult = "Stato rilevato: \(res.state.rawValue)\nRisposta: \(res.rawDetails)"
            }
        }
    }
    
    private func commitConfiguration() {
        vmConfig.lastAttestationDate = Date()
        utmService.saveConfiguration(vmConfig)
        
        // Aggiorna lo stato globale dell'app
        appState.prerequisites.authorizedVMName = vmConfig.vmName
        appState.isolationChecklist.vmNetworkDisconnected = vmConfig.isNetworkIsolated
        appState.isolationChecklist.hostFolderSharingDisabled = vmConfig.isFolderSharingDisabled
        appState.isolationChecklist.sharedClipboardDisabled = vmConfig.isClipboardSharingDisabled
        appState.isolationChecklist.noUsbPassthrough = vmConfig.isUsbPassthroughDisabled
        appState.isolationChecklist.cleanSnapshotVerified = vmConfig.hasCleanSnapshot
        
        if vmConfig.isFullyHardened && appState.prerequisites.isUTMInstalled {
            appState.vmStatus = .verified
        } else {
            appState.vmStatus = .manualVerificationRequired
        }
        
        auditLogger.log(
            level: .info,
            category: .system,
            source: "UTMWizard",
            description: "Configurazione Sandbox UTM v0.2 completata dall'utente.",
            details: "VM: \(vmConfig.vmName), Indurimento: \(vmConfig.complianceScore.passed)/\(vmConfig.complianceScore.total), Stato finale: \(appState.vmStatus.rawValue)",
            isSimulation: false
        )
        
        dismiss()
    }
}
