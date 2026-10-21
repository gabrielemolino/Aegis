import Foundation
import CryptoKit

public enum PreflightResult: Equatable {
    case passed
    case failed(reasons: [String])
}

@MainActor
public final class SecurityEngine: ObservableObject {
    public static let shared = SecurityEngine()
    
    @Published public private(set) var activeAnalysisState: AnalysisRunState = .idle
    @Published public private(set) var currentReport: AnalysisReport? = nil
    @Published public private(set) var analysisProgress: Double = 0.0
    @Published public private(set) var elapsedTimeSeconds: Int = 0
    @Published public private(set) var isAnalysisActive: Bool = false
    
    private var analysisTask: Task<Void, Never>? = nil
    private let auditLogger = AuditLogger.shared
    
    public init() {}
    
    /// Calcola in modo sicuro l'hash SHA-256 e le proprietà del file SENZA eseguirlo
    public func inspectFileSafely(at url: URL) throws -> SafeTargetFile {
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer {
            try? fileHandle.close()
        }
        
        var hasher = SHA256()
        let bufferSize = 64 * 1024 // 64 KB chunks
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}
        
        let digest = hasher.finalize()
        let sha256String = digest.map { String(format: "%02hhx", $0) }.joined()
        
        auditLogger.log(
            level: .info,
            category: .preflight,
            source: "SafeFileInspector",
            description: "File analizzato staticamente sull'host: \(url.lastPathComponent)",
            details: "Dimensione: \(fileSize) byte, SHA256: \(sha256String) (File NON eseguito)",
            isSimulation: false
        )
        
        return SafeTargetFile(
            name: url.lastPathComponent,
            path: url.path,
            sizeBytes: fileSize,
            sha256: sha256String,
            detectedMimeType: url.pathExtension.isEmpty ? "application/octet-stream" : "file/\(url.pathExtension)"
        )
    }
    
    /// Valuta i controlli obbligatori di preflight secondo la policy Fail-Closed
    public func evaluatePreflight(
        targetFile: SafeTargetFile?,
        prerequisites: VMPrerequisites,
        isolation: IsolationChecklist,
        vmStatus: VMStatus
    ) -> PreflightResult {
        var reasons: [String] = []
        
        if targetFile == nil {
            reasons.append("Nessun file selezionato per l'analisi.")
        }
        
        if !prerequisites.isAppleSilicon {
            reasons.append("Architettura Apple Silicon non rilevata.")
        }
        
        if !prerequisites.isUTMInstalled {
            reasons.append("UTM non risulta installato in /Applications/UTM.app.")
        }
        
        if vmStatus != .verified {
            reasons.append("La VM di analisi non è in stato 'Verificata' (stato attuale: \(vmStatus.rawValue)).")
        }
        
        if !isolation.hostFolderSharingDisabled {
            reasons.append("Condivisione cartelle host attiva. Disattivarla prima dell'avvio.")
        }
        
        if !isolation.sharedClipboardDisabled {
            reasons.append("Condivisione appunti host/guest attiva.")
        }
        
        if !isolation.vmNetworkDisconnected {
            reasons.append("Rete della VM attiva. La configurazione di default richiede isolamento totale.")
        }
        
        if !isolation.cleanSnapshotVerified {
            reasons.append("Stato snapshot/base pulita non confermato. Richiesta verifica manuale.")
        }
        
        if !isolation.noUsbPassthrough {
            reasons.append("Dispositivi USB passthrough collegati alla VM.")
        }
        
        if reasons.isEmpty {
            auditLogger.log(
                level: .info,
                category: .preflight,
                source: "PreflightValidator",
                description: "Tutti i controlli preflight superati con successo.",
                isSimulation: false
            )
            return .passed
        } else {
            auditLogger.log(
                level: .warning,
                category: .preflight,
                source: "PreflightValidator",
                description: "Preflight fallito (Fail-Closed). Avvio bloccato.",
                details: reasons.joined(separator: "; "),
                isSimulation: false
            )
            return .failed(reasons: reasons)
        }
    }
    
    /// Esegue una sessione simulata di analisi sicura per la v0.1 (dati dimostrativi innocui)
    public func runSimulatedAnalysis(
        for file: SafeTargetFile,
        scenario: SimulatedScenario = .suspiciousActivity,
        onProgress: @escaping @MainActor @Sendable (Double, Int) -> Void,
        onCompletion: @escaping @MainActor @Sendable (AnalysisReport) -> Void
    ) {
        stopAnalysis()
        
        activeAnalysisState = .running
        isAnalysisActive = true
        analysisProgress = 0.0
        elapsedTimeSeconds = 0
        currentReport = nil
        
        auditLogger.log(
            level: .info,
            category: .analysis,
            source: "AnalysisController",
            description: "Avvio simulazione analisi comportamentale per file: \(file.name)",
            details: "[SIMULAZIONE v0.1] Nessun file reale copiato o eseguito",
            isSimulation: true
        )
        
        let totalTicks = 8
        
        analysisTask = Task { @MainActor [weak self] in
            for currentTick in 1...totalTicks {
                do {
                    try await Task.sleep(nanoseconds: 600_000_000)
                } catch {
                    return
                }
                
                guard let self = self, self.isAnalysisActive, !Task.isCancelled else {
                    return
                }
                
                self.elapsedTimeSeconds += 1
                self.analysisProgress = min(Double(currentTick) / Double(totalTicks), 1.0)
                onProgress(self.analysisProgress, self.elapsedTimeSeconds)
                
                // Simula eventi intermedi conformi alle specifiche
                switch currentTick {
                case 2:
                    self.auditLogger.log(
                        level: .info,
                        category: .analysis,
                        source: "GuestSensorMock",
                        description: "[SIMULAZIONE] Snapshot pulito ripristinato su VM autorizzata",
                        isSimulation: true
                    )
                case 4:
                    self.auditLogger.log(
                        level: .warning,
                        category: .rules,
                        source: "RuleEngine",
                        description: "[SIMULAZIONE] Rilevate 14 scritture consecutive in /tmp dal processo simulato",
                        details: "Regola R-014: TempDirHighWriteRate superata",
                        isSimulation: true
                    )
                case 6:
                    if scenario == .suspiciousActivity || scenario == .criticalMalware {
                        self.auditLogger.log(
                            level: .critical,
                            category: .containment,
                            source: "HostController",
                            description: "[SIMULAZIONE] Trigger contenimento: inviato segnale stop alla VM autorizzata",
                            details: "Arresto preventivo registrato senza perdita dati host",
                            isSimulation: true
                        )
                    }
                case 8:
                    self.isAnalysisActive = false
                    self.activeAnalysisState = .completed
                    
                    let report = self.buildSimulatedReport(for: file, scenario: scenario)
                    self.currentReport = report
                    
                    self.auditLogger.log(
                        level: .info,
                        category: .analysis,
                        source: "AnalysisController",
                        description: "Simulazione completata. Esito: \(report.classification.rawValue)",
                        details: "Confidenza: \(Int(report.confidenceScore * 100))%",
                        isSimulation: true
                    )
                    
                    onCompletion(report)
                default:
                    break
                }
            }
        }
    }
    
    /// Interrompe immediatamente l'analisi in corso
    public func stopAnalysis() {
        if isAnalysisActive {
            analysisTask?.cancel()
            analysisTask = nil
            isAnalysisActive = false
            activeAnalysisState = .stopped
            
            auditLogger.log(
                level: .warning,
                category: .containment,
                source: "HostController",
                description: "Analisi interrotta manualmente dall'utente. Attuato contenimento immediato.",
                isSimulation: true
            )
        }
    }
    
    public enum SimulatedScenario: String, CaseIterable, Identifiable, Sendable, Codable {
        case clean = "Campione Innocuo (Clean)"
        case suspiciousActivity = "Attività Sospetta (/tmp burst)"
        case criticalMalware = "Comportamento Critico (Arresto VM)"
        case unverifiable = "Ambiente Non Verificabile"
        
        public var id: String { rawValue }
    }
    
    private func buildSimulatedReport(for file: SafeTargetFile, scenario: SimulatedScenario) -> AnalysisReport {
        switch scenario {
        case .clean:
            return AnalysisReport(
                targetFile: file,
                classification: .notDetected,
                confidenceScore: 0.92,
                summary: "Nessun indicatore malevolo rilevato nei test simulati di baseline.",
                evidence: [
                    "Nessuna connessione di rete tentata.",
                    "Accesso limitato alle risorse allocate.",
                    "Terminazione del processo con codice di uscita standard (0)."
                ],
                rulesTriggered: [
                    RuleTrigger(
                        id: "RULE-SAFE-001",
                        ruleName: "StandardProcessLifecycle",
                        severity: .info,
                        description: "Processo avviato e terminato regolarmente nel guest di test.",
                        matchedIndicator: "exit_code == 0"
                    )
                ],
                actionsExecuted: [
                    ContainmentAction(
                        actionType: "Verifica integrità guest",
                        targetVM: "SentinelAI-Ubuntu-Guest",
                        status: "Completata con successo",
                        isSimulation: true
                    )
                ],
                limitations: [
                    "I controlli dinamici sono limitati al tempo di esecuzione concesso (15s).",
                    "Possibile presenza di evasione sandbox tramite time-delay o evasion heuristics.",
                    "Non costituisce garanzia assoluta di assenza di codice malevolo."
                ],
                isSimulatedDemo: true
            )
            
        case .suspiciousActivity:
            return AnalysisReport(
                targetFile: file,
                classification: .suspicious,
                confidenceScore: 0.78,
                summary: "Rilevata attività anomala nel filesystem temporaneo del guest.",
                evidence: [
                    "Creazione anomala di 14 file in /tmp/ in meno di 800ms.",
                    "Tentativo di esecuzione di script figlio non autorizzato.",
                    "Modifica di attributi su eseguibili nascosti."
                ],
                rulesTriggered: [
                    RuleTrigger(
                        id: "RULE-IO-014",
                        ruleName: "TempDirBurstWrites",
                        severity: .medium,
                        description: "Scrittura massiva non standard nella cartella temporanea.",
                        matchedIndicator: "count(/tmp/*) > 10 in 1s"
                    ),
                    RuleTrigger(
                        id: "RULE-PROC-005",
                        ruleName: "UnexpectedChildProcess",
                        severity: .medium,
                        description: "Spawning di shell secondaria non richiesta.",
                        matchedIndicator: "child_process: /bin/sh -c"
                    )
                ],
                actionsExecuted: [
                    ContainmentAction(
                        actionType: "Generazione Alert & Notifica UI",
                        targetVM: "SentinelAI-Ubuntu-Guest",
                        status: "Attivata",
                        isSimulation: true
                    )
                ],
                limitations: [
                    "Nessun traffico di rete osservato a causa dell'isolamento totale attivo.",
                    "Simulazione basata su fixture comportamentale prefissata v0.1."
                ],
                isSimulatedDemo: true
            )
            
        case .criticalMalware:
            return AnalysisReport(
                targetFile: file,
                classification: .detected,
                confidenceScore: 0.96,
                summary: "Rilevato comportamento ostile critico con tentata propagazione.",
                evidence: [
                    "Tentativo di scansione porte localhost e probing socket locali.",
                    "Modifica aggressiva delle tabelle crontab e systemd unit nel guest.",
                    "Pattern di sovrascrittura compatibile con tentativi di estorsione/cifratura."
                ],
                rulesTriggered: [
                    RuleTrigger(
                        id: "RULE-PERSIST-002",
                        ruleName: "UnauthorizedSystemdService",
                        severity: .critical,
                        description: "Tentativo di installare un servizio persistente con privilegi.",
                        matchedIndicator: "write: /etc/systemd/system/mal.service"
                    ),
                    RuleTrigger(
                        id: "RULE-CRYPTO-009",
                        ruleName: "RapidFileEntropyShift",
                        severity: .critical,
                        description: "Incremento drastico dell'entropia nei documenti utente.",
                        matchedIndicator: "entropy > 7.95 in 20 files"
                    )
                ],
                actionsExecuted: [
                    ContainmentAction(
                        actionType: "Arresto forzato VM autorizzata",
                        targetVM: "SentinelAI-Ubuntu-Guest",
                        status: "Eseguito con successo dal controller",
                        isSimulation: true
                    ),
                    ContainmentAction(
                        actionType: "Blocco scrittura disco e marcatura snapshot sporco",
                        targetVM: "SentinelAI-Ubuntu-Guest",
                        status: "Completato",
                        isSimulation: true
                    )
                ],
                limitations: [
                    "La VM è stata arrestata per contenimento. Per ulteriori analisi è necessario ripristinare la base pulita.",
                    "L'esito dimostra la funzionalità di spegnimento immediato del controller host."
                ],
                isSimulatedDemo: true
            )
            
        case .unverifiable:
            return AnalysisReport(
                targetFile: file,
                classification: .unverifiable,
                confidenceScore: 0.15,
                summary: "L'ambiente isolato ha riscontrato un'interruzione di telemetria. Analisi non verificabile.",
                evidence: [
                    "Heartbeat del sensore guest assente o timeout scaduto.",
                    "Impossibile attestare l'integrità del log comportamentale."
                ],
                rulesTriggered: [
                    RuleTrigger(
                        id: "RULE-HEALTH-000",
                        ruleName: "GuestSensorTimeout",
                        severity: .high,
                        description: "Canale sensore disconnesso prima del termine della sessione.",
                        matchedIndicator: "heartbeat_delta > 10s"
                    )
                ],
                actionsExecuted: [
                    ContainmentAction(
                        actionType: "Sospensione e marcatura ambiente degradato",
                        targetVM: "SentinelAI-Ubuntu-Guest",
                        status: "Applicato policy di sicurezza fail-closed",
                        isSimulation: true
                    )
                ],
                limitations: [
                    "Nessun giudizio espresso sul file: l'esito è esplicitamente 'Non verificabile'.",
                    "Non fidarsi di esiti incompleti quando l'infrastruttura di monitoraggio degrada."
                ],
                isSimulatedDemo: true
            )
        }
    }
}
