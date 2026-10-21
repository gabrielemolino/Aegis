import SwiftUI
import Combine

public enum SidebarTab: String, CaseIterable, Identifiable {
    case overview = "Panoramica"
    case sandbox = "Sandbox"
    case analysis = "Analisi"
    case events = "Eventi"
    case settings = "Impostazioni"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .sandbox: return "cube.transparent.fill"
        case .analysis: return "waveform.path.ecg"
        case .events: return "list.bullet.rectangle"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: SidebarTab = .overview
    @Published public var prerequisites: VMPrerequisites
    @Published public var vmStatus: VMStatus = .notConfigured
    @Published public var isolationChecklist: IsolationChecklist = IsolationChecklist()
    @Published public var targetFile: SafeTargetFile? = nil
    @Published public var preflightResult: PreflightResult? = nil
    
    @Published public var recentAnalyses: [AnalysisReport] = []
    @Published public var selectedScenario: SecurityEngine.SimulatedScenario = .suspiciousActivity
    @Published public var showOnboardingModal: Bool = false
    
    // Configurazione Regole & LLM
    public let ruleEngineVersion: String = "v0.1.0-ruleset-baseline"
    public let ruleCount: Int = 42
    public let aiAnalystStatus: String = "Non configurato (Opzionale v0.6)"
    
    private let systemCheckService = SystemCheckService.shared
    private let securityEngine = SecurityEngine.shared
    private let auditLogger = AuditLogger.shared
    
    public init() {
        let prereqs = systemCheckService.inspectEnvironment()
        self.prerequisites = prereqs
        
        // Carica la configurazione UTM persistita (Milestone v0.2)
        let utmConfig = UTMManagementService.shared.loadConfiguration()
        self.prerequisites.authorizedVMName = utmConfig.vmName
        self.isolationChecklist.vmNetworkDisconnected = utmConfig.isNetworkIsolated
        self.isolationChecklist.hostFolderSharingDisabled = utmConfig.isFolderSharingDisabled
        self.isolationChecklist.sharedClipboardDisabled = utmConfig.isClipboardSharingDisabled
        self.isolationChecklist.noUsbPassthrough = utmConfig.isUsbPassthroughDisabled
        self.isolationChecklist.cleanSnapshotVerified = utmConfig.hasCleanSnapshot
        
        // Determina lo stato iniziale della Sandbox UTM
        if prereqs.isUTMInstalled && utmConfig.isFullyHardened {
            self.vmStatus = .verified
        } else if prereqs.isUTMInstalled {
            self.vmStatus = .manualVerificationRequired
        } else {
            self.vmStatus = .notConfigured
        }
    }
    
    /// Calcola lo stato generale della protezione host
    public var overallProtectionStatus: OverallProtectionStatus {
        if vmStatus == .verified && isolationChecklist.allRequirementsMet {
            return .fullyProtected
        } else if vmStatus == .notConfigured {
            return .notConfigured
        } else if vmStatus == .insecure {
            return .insecure
        } else {
            return .partial
        }
    }
    
    /// Esegue nuovamente i controlli ambientali
    public func refreshEnvironment() {
        self.prerequisites = systemCheckService.inspectEnvironment()
        auditLogger.log(
            level: .info,
            category: .system,
            source: "EnvironmentAuditor",
            description: "Controllo prerequisiti aggiornato.",
            details: "Apple Silicon: \(prerequisites.isAppleSilicon), macOS: \(prerequisites.macOSVersion), UTM: \(prerequisites.isUTMInstalled ? "Trovato" : "Non trovato")"
        )
    }
    
    /// Consente all'utente di attestare la verifica manuale dei parametri VM
    public func toggleManualVerificationForSnapshot() {
        isolationChecklist.cleanSnapshotVerified.toggle()
        if isolationChecklist.cleanSnapshotVerified {
            auditLogger.log(
                level: .warning,
                category: .preflight,
                source: "UserAttestation",
                description: "L'utente ha attestato manualmente la conformità dello snapshot pulito",
                details: "Verifica manuale confermata per la sessione corrente"
            )
            // Se UTM è presente e i requisiti base ci sono, aggiorna stato VM
            if prerequisites.isUTMInstalled {
                self.vmStatus = .verified
            }
        } else {
            self.vmStatus = .manualVerificationRequired
        }
    }
    
    /// Seleziona un file da esaminare in modo sicuro
    public func selectFile(url: URL) {
        do {
            let safeFile = try securityEngine.inspectFileSafely(at: url)
            self.targetFile = safeFile
            self.preflightResult = nil
        } catch {
            auditLogger.log(
                level: .warning,
                category: .preflight,
                source: "FileSelector",
                description: "Impossibile ispezionare il file selezionato: \(error.localizedDescription)"
            )
        }
    }
    
    @Published public var currentVMExecutionState: UTMVMExecutionState = .unknown
    @Published public var isExecutingVMCommand: Bool = false
    @Published public var lastVMCommandMessage: String? = nil
    @Published public var isCompromisedAwaitingRollback: Bool = false
    
    // MARK: - Telemetria Guest (Milestone v0.5)
    @Published public var importedTelemetryResult: IngestionAnalysisResult? = nil
    @Published public var isUsingRealTelemetry: Bool = false

    /// Esegue il controllo preflight per il file selezionato
    public func performPreflight() -> Bool {
        let result = securityEngine.evaluatePreflight(
            targetFile: targetFile,
            prerequisites: prerequisites,
            isolation: isolationChecklist,
            vmStatus: vmStatus
        )
        self.preflightResult = result
        return result == .passed
    }
    
    /// Importa un file di telemetria guest (.jsonl) e lo valuta con il motore deterministico
    public func importGuestTelemetry(from url: URL) {
        do {
            let res = try TelemetryIngestionService.shared.parseEvents(from: url)
            let analysisRes = TelemetryIngestionService.shared.evaluateIngestedTelemetry(events: res.events, corruptedCount: res.corruptedCount)
            self.importedTelemetryResult = analysisRes
            self.isUsingRealTelemetry = true
            self.lastVMCommandMessage = "Caricati \(analysisRes.validEventsCount) eventi di telemetria da \(url.lastPathComponent)."
        } catch {
            auditLogger.log(
                level: .warning,
                category: .analysis,
                source: "AppState",
                description: "Errore lettura file telemetria: \(url.lastPathComponent)",
                details: error.localizedDescription,
                isSimulation: false
            )
            self.lastVMCommandMessage = "Errore lettura file: \(error.localizedDescription)"
        }
    }
    
    /// Importa direttamente una stringa JSONL (es. da simulatore o stream del sensore)
    public func importGuestTelemetry(jsonlText: String, sourceDescription: String = "Stream Diretto") {
        let res = TelemetryIngestionService.shared.parseEvents(from: jsonlText)
        let analysisRes = TelemetryIngestionService.shared.evaluateIngestedTelemetry(events: res.events, corruptedCount: res.corruptedCount)
        self.importedTelemetryResult = analysisRes
        self.isUsingRealTelemetry = true
        self.lastVMCommandMessage = "Caricati \(analysisRes.validEventsCount) eventi (\(sourceDescription))."
    }
    
    /// Avvia l'analisi deterministica basata sulla telemetria reale del sensore guest
    public func startRealTelemetryAnalysis() {
        guard let file = targetFile else { return }
        guard let res = importedTelemetryResult else { return }
        guard performPreflight() else { return }
        
        let report = securityEngine.runAnalysis(
            from: res,
            for: file,
            vmName: prerequisites.authorizedVMName
        )
        self.recentAnalyses.insert(report, at: 0)
        
        // Se l'analisi rileva malware critico, attiva l'obbligo di rollback
        if report.classification == .detected {
            self.isCompromisedAwaitingRollback = true
            self.isolationChecklist.cleanSnapshotVerified = false
            self.vmStatus = .manualVerificationRequired
        }
    }
    
    /// Avvia l'analisi simulata con visualizzazione progressi
    public func startAnalysis(scenario: SecurityEngine.SimulatedScenario) {
        guard let file = targetFile else { return }
        guard performPreflight() else { return }
        
        securityEngine.runSimulatedAnalysis(
            for: file,
            scenario: scenario,
            onProgress: { _, _ in
                // aggiornamento in tempo reale
            },
            onCompletion: { [weak self] report in
                guard let self = self else { return }
                self.recentAnalyses.insert(report, at: 0)
                
                // Se l'analisi ha rilevato attività critica/ostile, richiede rollback
                if report.classification == .detected {
                    self.isCompromisedAwaitingRollback = true
                    self.isolationChecklist.cleanSnapshotVerified = false
                    self.vmStatus = .manualVerificationRequired
                }
            }
        )
    }
    
    /// Interrompe l'analisi corrente e invia il segnale di arresto di contenimento
    public func stopAnalysis() {
        securityEngine.stopAnalysis()
        
        // Attua contenimento immediato sulla sola VM autorizzata
        Task {
            let res = await VMHostController.shared.stopVM(
                targetVM: prerequisites.authorizedVMName,
                authorizedVM: prerequisites.authorizedVMName,
                mode: .containmentImmediate,
                triggeredByRule: "ManualeOperatore"
            )
            await MainActor.run {
                self.currentVMExecutionState = res.isSuccess ? .stopped : .unknown
                self.lastVMCommandMessage = res.message
                self.isCompromisedAwaitingRollback = true
                self.isolationChecklist.cleanSnapshotVerified = false
                self.vmStatus = .manualVerificationRequired
            }
        }
    }
    
    // MARK: - Controllo VM Host (Milestone v0.4)
    
    /// Interroga in modo asincrono lo stato corrente della VM in UTM
    public func checkLiveVMStatus() {
        isExecutingVMCommand = true
        Task {
            let res = await UTMManagementService.shared.queryVMStatus(vmName: prerequisites.authorizedVMName)
            await MainActor.run {
                self.isExecutingVMCommand = false
                self.currentVMExecutionState = res.state
                self.lastVMCommandMessage = "Stato VM '\(self.prerequisites.authorizedVMName)': \(res.state.rawValue)"
            }
        }
    }
    
    /// Avvia la VM autorizzata tramite il controller host
    public func startAuthorizedVM() {
        isExecutingVMCommand = true
        lastVMCommandMessage = "Invio comando di avvio per '\(prerequisites.authorizedVMName)'..."
        Task {
            let res = await VMHostController.shared.startVM(
                targetVM: prerequisites.authorizedVMName,
                authorizedVM: prerequisites.authorizedVMName
            )
            await MainActor.run {
                self.isExecutingVMCommand = false
                if res.isSuccess {
                    self.currentVMExecutionState = .running
                    self.lastVMCommandMessage = res.message
                } else {
                    self.lastVMCommandMessage = res.message
                }
            }
        }
    }
    
    /// Arresta la VM autorizzata (graceful o contenimento immediato)
    public func stopAuthorizedVM(mode: VMStopMode) {
        isExecutingVMCommand = true
        lastVMCommandMessage = "Invio comando di arresto (\(mode.rawValue)) per '\(prerequisites.authorizedVMName)'..."
        Task {
            let res = await VMHostController.shared.stopVM(
                targetVM: prerequisites.authorizedVMName,
                authorizedVM: prerequisites.authorizedVMName,
                mode: mode,
                triggeredByRule: mode == .containmentImmediate ? "ContenimentoManuale" : "SpegnimentoOrdinato"
            )
            await MainActor.run {
                self.isExecutingVMCommand = false
                if res.isSuccess {
                    self.currentVMExecutionState = .stopped
                    self.lastVMCommandMessage = res.message
                    // Dopo l'arresto, lo snapshot deve essere confermato pulito prima del prossimo avvio
                    self.isCompromisedAwaitingRollback = true
                    self.isolationChecklist.cleanSnapshotVerified = false
                    self.vmStatus = .manualVerificationRequired
                } else {
                    self.lastVMCommandMessage = res.message
                }
            }
        }
    }
    
    /// Attesta l'avvenuto rollback a snapshot pulito post-contenimento
    public func attestSnapshotRollbackCompleted() {
        isolationChecklist.cleanSnapshotVerified = true
        isCompromisedAwaitingRollback = false
        
        if prerequisites.isUTMInstalled && isolationChecklist.allRequirementsMet {
            vmStatus = .verified
        }
        
        auditLogger.log(
            level: .info,
            category: .containment,
            source: "UserAttestation",
            description: "Rollback da snapshot pulito 'clean-baseline' attestato dall'operatore.",
            details: "Stato VM '\(prerequisites.authorizedVMName)' bonificato. Ambiente reimpostato a Conforme.",
            isSimulation: false
        )
        
        lastVMCommandMessage = "Rollback attestato con successo. Sandbox ripristinata e conforme."
    }
}
