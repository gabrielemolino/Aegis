import Foundation

public final class UTMManagementService: Sendable {
    public static let shared = UTMManagementService()
    
    private let userDefaultsKey = "org.sentinelai.utm_config_v02"
    
    public init() {}
    
    /// Valida il nome della VM per impedire command injection o caratteri illegali
    public func validateVMName(_ name: String) -> (isValid: Bool, sanitized: String, errorReason: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return (false, "", "Il nome della VM non può essere vuoto.")
        }
        
        if trimmed.count > 64 {
            return (false, String(trimmed.prefix(64)), "Il nome della VM non può superare i 64 caratteri.")
        }
        
        // Consentiti solo lettere, cifre, trattini e underscore
        let allowedCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let nameCharacterSet = CharacterSet(charactersIn: trimmed)
        
        if !allowedCharacterSet.isSuperset(of: nameCharacterSet) {
            let sanitized = trimmed.filter { char in
                char.isLetter || char.isNumber || char == "-" || char == "_"
            }
            return (false, sanitized, "Il nome contiene caratteri speciali non consentiti. Usa solo lettere, numeri, trattini e underscore.")
        }
        
        return (true, trimmed, nil)
    }
    
    /// Interroga in modo sicuro lo stato di una VM tramite utmctl con timeout rigoroso (non bloccante)
    public func queryVMStatus(vmName: String, timeout: TimeInterval = 1.5) async -> (state: UTMVMExecutionState, rawDetails: String) {
        let validation = validateVMName(vmName)
        guard validation.isValid else {
            return (.unknown, "Nome VM non valido: \(validation.errorReason ?? "")")
        }
        
        let utmInfo = SystemCheckService.shared.checkUTMInstallation()
        guard let cliPath = utmInfo.cliPath, FileManager.default.isExecutableFile(atPath: cliPath) else {
            return (.unknown, "Strumento CLI utmctl non disponibile o non eseguibile.")
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: cliPath)
                // Passaggio argomenti come array separato: NESSUNA concatenazione shell
                process.arguments = ["status", validation.sanitized]
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                var hasResponded = false
                let lock = NSLock()
                
                let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
                timer.schedule(deadline: .now() + timeout)
                timer.setEventHandler {
                    lock.lock()
                    defer { lock.unlock() }
                    if !hasResponded {
                        hasResponded = true
                        if process.isRunning {
                            process.terminate()
                        }
                        continuation.resume(returning: (
                            .unknown,
                            "Timeout (\(timeout)s) interrogazione UTM: l'app UTM potrebbe essere chiusa o non responsiva."
                        ))
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
                        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let output = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        let errOutput = (String(data: errData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let combined = output.isEmpty ? errOutput : output
                        
                        let state: UTMVMExecutionState
                        let lower = combined.lowercased()
                        if lower.contains("stopped") || lower.contains("inactive") {
                            state = .stopped
                        } else if lower.contains("started") || lower.contains("running") {
                            state = .running
                        } else if lower.contains("paused") || lower.contains("suspended") {
                            state = .suspended
                        } else {
                            state = .unknown
                        }
                        
                        continuation.resume(returning: (state, combined))
                    }
                } catch {
                    lock.lock()
                    defer { lock.unlock() }
                    timer.cancel()
                    if !hasResponded {
                        hasResponded = true
                        continuation.resume(returning: (.unknown, "Errore avvio utmctl: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }
    
    /// Salva la configurazione validata nelle preferenze locali
    public func saveConfiguration(_ config: UTMVMConfig) {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    /// Carica la configurazione salvata, oppure restituisce la baseline predefinita
    public func loadConfiguration() -> UTMVMConfig {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(UTMVMConfig.self, from: data) else {
            return UTMVMConfig()
        }
        return decoded
    }
    
    /// Valuta la conformità della configurazione rispetto ai 5 requisiti non negoziabili
    public func verifyIsolationChecklist(config: UTMVMConfig) -> (isCompliant: Bool, missingSteps: [String]) {
        var missing: [String] = []
        
        if !config.isNetworkIsolated {
            missing.append("Rete disconnessa (Network Mode: None)")
        }
        if !config.isFolderSharingDisabled {
            missing.append("Nessuna cartella condivisa (Shared Directory: None)")
        }
        if !config.isClipboardSharingDisabled {
            missing.append("Condivisione appunti disabilitata (Clipboard sharing: Disabled)")
        }
        if !config.isUsbPassthroughDisabled {
            missing.append("USB passthrough disabilitato (Nessuna periferica host)")
        }
        if !config.hasCleanSnapshot {
            missing.append("Snapshot pulito 'clean-baseline' verificato prima dell'analisi")
        }
        
        return (missing.isEmpty, missing)
    }
}
