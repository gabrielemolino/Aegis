import Foundation

/// Modalità di arresto per il contenimento o spegnimento ordinato
public enum VMStopMode: String, Codable, Sendable {
    case graceful = "Spegnimento Ordinato (Graceful)"
    case containmentImmediate = "Arresto Immediato di Contenimento (Kill/Stop)"
}

/// Esito di un comando impartito dal controller host alla VM
public enum VMCommandResult: Sendable, Equatable {
    case success(message: String, confirmedState: UTMVMExecutionState)
    case failed(reason: String, confirmedState: UTMVMExecutionState?)
    
    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failed: return false
        }
    }
    
    public var message: String {
        switch self {
        case .success(let msg, _): return msg
        case .failed(let reason, _): return reason
        }
    }
}

/// Controller host per la gestione del ciclo di vita e contenimento della sola VM autorizzata
public final class VMHostController: Sendable {
    public static let shared = VMHostController()
    
    private let utmService = UTMManagementService.shared
    private let auditLogger = AuditLogger.shared
    
    public init() {}
    
    /// Avvia la VM designata, con verifica rigorosa di autorizzazione e conferma dello stato
    public func startVM(
        targetVM: String,
        authorizedVM: String,
        isSimulation: Bool = false
    ) async -> VMCommandResult {
        // 1. Vincolo di sicurezza: autorizzazione esclusiva per la VM designata
        guard isAuthorized(targetVM: targetVM, authorizedVM: authorizedVM) else {
            let reason = "Accesso negato: Il controller host accetta comandi ESCLUSIVAMENTE per la VM autorizzata '\(authorizedVM)'. Rifiutato comando per '\(targetVM)'."
            logAction(action: "START_REJECTED", targetVM: targetVM, success: false, details: reason, isSimulation: isSimulation)
            return .failed(reason: reason, confirmedState: nil)
        }
        
        // Modalità simulata (utilizzata nei test unitari o in assenza di hypervisor attivo)
        if isSimulation {
            logAction(action: "START_VM", targetVM: targetVM, success: true, details: "VM avviata con successo [SIMULAZIONE]", isSimulation: true)
            return .success(message: "VM '\(targetVM)' avviata regolarmente [SIMULAZIONE].", confirmedState: .running)
        }
        
        let utmInfo = SystemCheckService.shared.checkUTMInstallation()
        guard let cliPath = utmInfo.cliPath, FileManager.default.isExecutableFile(atPath: cliPath) else {
            let reason = "Impossibile avviare la VM: eseguibile utmctl non disponibile in \(utmInfo.cliPath ?? "path sconosciuto")."
            logAction(action: "START_FAILED", targetVM: targetVM, success: false, details: reason, isSimulation: false)
            return .failed(reason: reason, confirmedState: .unknown)
        }
        
        // Esecuzione processo senza shell concatenation
        let processResult = await executeUTMProcess(cliPath: cliPath, arguments: ["start", targetVM], timeout: 4.0)
        
        // Attesa breve per permettere la transizione di stato
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        // Conferma effettiva dello stato (nessun falso successo)
        let query = await utmService.queryVMStatus(vmName: targetVM, timeout: 2.0)
        if query.state == .running {
            let msg = "VM '\(targetVM)' avviata con successo e stato confermato in esecuzione."
            logAction(action: "START_VM", targetVM: targetVM, success: true, details: msg, isSimulation: false)
            return .success(message: msg, confirmedState: .running)
        } else {
            let reason = "Avvio non confermato per '\(targetVM)': lo stato rilevato è '\(query.state.rawValue)' (Output: \(processResult.output))."
            logAction(action: "START_FAILED", targetVM: targetVM, success: false, details: reason, isSimulation: false)
            return .failed(reason: reason, confirmedState: query.state)
        }
    }
    
    /// Arresta la VM designata per contenimento o chiusura ordinata, con conferma rigorosa dell'arresto
    public func stopVM(
        targetVM: String,
        authorizedVM: String,
        mode: VMStopMode = .containmentImmediate,
        triggeredByRule: String? = nil,
        isSimulation: Bool = false
    ) async -> VMCommandResult {
        // 1. Vincolo di sicurezza: autorizzazione esclusiva per la VM designata
        guard isAuthorized(targetVM: targetVM, authorizedVM: authorizedVM) else {
            let reason = "Contenimento rifiutato: Tentativo non autorizzato di arrestare la VM estranea '\(targetVM)'. Consentita solo '\(authorizedVM)'."
            logAction(action: "STOP_REJECTED", targetVM: targetVM, success: false, details: reason, isSimulation: isSimulation)
            return .failed(reason: reason, confirmedState: nil)
        }
        
        // Modalità simulata
        if isSimulation {
            let detail = "Contenimento simulato: inviato segnale stop alla VM '\(targetVM)' per regola \(triggeredByRule ?? "Manuale")."
            logAction(action: "CONTAINMENT_STOP", targetVM: targetVM, success: true, details: detail, isSimulation: true)
            return .success(message: "Contenimento eseguito con successo sulla VM autorizzata '\(targetVM)' [SIMULAZIONE].", confirmedState: .stopped)
        }
        
        let utmInfo = SystemCheckService.shared.checkUTMInstallation()
        guard let cliPath = utmInfo.cliPath, FileManager.default.isExecutableFile(atPath: cliPath) else {
            let reason = "Contenimento non confermato: utmctl non disponibile."
            logAction(action: "STOP_FAILED", targetVM: targetVM, success: false, details: reason, isSimulation: false)
            return .failed(reason: reason, confirmedState: .unknown)
        }
        
        // Esecuzione processo di stop
        let processResult = await executeUTMProcess(cliPath: cliPath, arguments: ["stop", targetVM], timeout: 5.0)
        
        // Verifica con polling (fino a 3 secondi) per confermare l'arresto reale
        var confirmedState: UTMVMExecutionState = .unknown
        for _ in 1...6 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let q = await utmService.queryVMStatus(vmName: targetVM, timeout: 1.5)
            confirmedState = q.state
            if confirmedState == .stopped {
                break
            }
        }
        
        // Obbligo Sezione 10: "Errore del controller: mostra 'contenimento non confermato'; non mostrare un falso successo"
        if confirmedState == .stopped {
            let msg = "Contenimento confermato: la sola VM autorizzata '\(targetVM)' è stata arrestata con successo."
            let detailMsg = "Regola trigger: \(triggeredByRule ?? "Comando manuale operatore"). Stato guest: Arrestato. Output: \(processResult.output)"
            logAction(action: "CONTAINMENT_STOP_SUCCESS", targetVM: targetVM, success: true, details: detailMsg, isSimulation: false)
            return .success(message: msg, confirmedState: .stopped)
        } else {
            let reason = "Contenimento non confermato: la VM '\(targetVM)' risulta ancora nello stato '\(confirmedState.rawValue)'. Nessun falso successo dichiarato."
            logAction(action: "CONTAINMENT_UNCONFIRMED", targetVM: targetVM, success: false, details: reason, isSimulation: false)
            return .failed(reason: reason, confirmedState: confirmedState)
        }
    }
    
    // MARK: - Helper di Sicurezza
    
    /// Verifica che il target richiesto corrisponda alla VM autorizzata configurata
    public func isAuthorized(targetVM: String, authorizedVM: String) -> Bool {
        let trimmedTarget = targetVM.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuth = authorizedVM.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTarget.isEmpty && !trimmedAuth.isEmpty else { return false }
        return trimmedTarget.caseInsensitiveCompare(trimmedAuth) == .orderedSame
    }
    
    private func executeUTMProcess(cliPath: String, arguments: [String], timeout: TimeInterval) async -> (success: Bool, output: String) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: cliPath)
                process.arguments = arguments
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                var hasResponded = false
                let lock = NSLock()
                
                let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
                timer.schedule(deadline: .now() + timeout)
                timer.setEventHandler {
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResponded {
                        hasResponded = true
                        if process.isRunning { process.terminate() }
                        continuation.resume(returning: (false, "Timeout (\(timeout)s)"))
                    }
                }
                timer.resume()
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    lock.lock()
                    defer { lock.unlock() }
                    timer.cancel()
                    if !hasResponded {
                        hasResponded = true
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let outStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        continuation.resume(returning: (process.terminationStatus == 0, outStr))
                    }
                } catch {
                    lock.lock()
                    defer { lock.unlock() }
                    timer.cancel()
                    if !hasResponded {
                        hasResponded = true
                        continuation.resume(returning: (false, error.localizedDescription))
                    }
                }
            }
        }
    }
    
    private func logAction(action: String, targetVM: String, success: Bool, details: String, isSimulation: Bool) {
        auditLogger.log(
            level: success ? .info : .warning,
            category: .containment,
            source: "VMHostController",
            description: "Azione \(action) su target '\(targetVM)': \(success ? "Successo" : "Fallimento/Rifiuto")",
            details: details,
            isSimulation: isSimulation
        )
    }
}
