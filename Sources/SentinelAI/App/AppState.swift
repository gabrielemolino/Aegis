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
            }
        )
    }
    
    /// Interrompe l'analisi corrente
    public func stopAnalysis() {
        securityEngine.stopAnalysis()
    }
}
