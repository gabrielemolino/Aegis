import Foundation

/// Motore di valutazione deterministico versionato e indipendente da LLM
public final class RuleEngineService: Sendable {
    public static let shared = RuleEngineService()
    
    public let engineVersion: String = "v0.3.0-ruleset-core"
    
    /// Catalogo completo delle regole deterministiche integrate
    public let rulesCatalog: [RuleDefinition] = [
        RuleDefinition(
            id: "RULE-SAFE-001",
            name: "StandardProcessLifecycle",
            category: .processAnomaly,
            severity: .info,
            description: "Processo ospite avviato e terminato regolarmente nel guest senza anomalie.",
            recommendedAction: .logAndMonitor
        ),
        RuleDefinition(
            id: "RULE-IO-014",
            name: "TempDirHighWriteRate",
            category: .behavioralIO,
            severity: .medium,
            description: "Rilevata scrittura massiva e frequente di file nella directory /tmp/ (superata soglia burst).",
            recommendedAction: .raiseWarningAlert
        ),
        RuleDefinition(
            id: "RULE-PROC-005",
            name: "UnexpectedChildProcess",
            category: .processAnomaly,
            severity: .medium,
            description: "Il processo ha generato un interprete o shell figlio inatteso (es. /bin/sh, /bin/bash, python).",
            recommendedAction: .requireUserConfirmation
        ),
        RuleDefinition(
            id: "RULE-PERSIST-002",
            name: "UnauthorizedPersistenceWrite",
            category: .persistence,
            severity: .critical,
            description: "Tentativo di installare un servizio persistente o script cron (/etc/systemd/, /etc/cron*).",
            recommendedAction: .stopAuthorizedVM
        ),
        RuleDefinition(
            id: "RULE-NET-003",
            name: "ViolatedIsolationEgressAttempt",
            category: .networkEgress,
            severity: .critical,
            description: "Tentativo di invio pacchetti di rete mentre l'isolamento della VM è attivo di default.",
            recommendedAction: .stopAuthorizedVM
        ),
        RuleDefinition(
            id: "RULE-HEARTBEAT-000",
            name: "SensorHeartbeatLoss",
            category: .telemetryHealth,
            severity: .high,
            description: "Heartbeat del sensore guest assente o timeout scaduto. Ambiente degradato (Fail-Closed).",
            recommendedAction: .markMonitoringDegraded
        ),
        RuleDefinition(
            id: "RULE-INJECT-001",
            name: "HostileLogPromptInjection",
            category: .antiTamper,
            severity: .low,
            description: "Rilevata stringa ostile o prompt injection nei log. Il contenuto è trattato rigorosamente come dato passivo.",
            recommendedAction: .treatAsDataOnly
        ),
        RuleDefinition(
            id: "RULE-CRYPTO-009",
            name: "RapidFileEntropyShift",
            category: .behavioralIO,
            severity: .critical,
            description: "Modifica a tappeto di estensioni e pattern I/O compatibili con ransomware o cifratura massiva.",
            recommendedAction: .stopAuthorizedVM
        )
    ]
    
    public init() {}
    
    /// Valuta una sequenza di eventi di telemetria contro l'intero catalogo di regole
    public func evaluate(
        events: [TelemetryEvent],
        tempWriteThreshold: Int = 10
    ) -> [RuleEvaluationMatch] {
        var matches: [RuleEvaluationMatch] = []
        
        // 1. Valutazione RULE-IO-014: TempDirHighWriteRate
        let tempWrites = events.filter { ev in
            ev.eventType == .fileIO &&
            (ev.filePath?.hasPrefix("/tmp/") ?? false || ev.filePath?.hasPrefix("/var/tmp/") ?? false) &&
            (ev.fileOperation == .create || ev.fileOperation == .write)
        }
        if tempWrites.count >= tempWriteThreshold {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-IO-014",
                    ruleName: "TempDirHighWriteRate",
                    severity: .medium,
                    category: .behavioralIO,
                    triggeredEventIDs: tempWrites.map { $0.id },
                    matchedIndicator: "Scritture in /tmp/ rilevate: \(tempWrites.count) (Soglia configurata: \(tempWriteThreshold))",
                    recommendedAction: .raiseWarningAlert
                )
            )
        }
        
        // 2. Valutazione RULE-PROC-005: UnexpectedChildProcess
        let suspiciousProcessNames = ["sh", "bash", "zsh", "python", "python3", "perl", "nc", "curl", "wget"]
        let childProcessEvents = events.filter { ev in
            ev.eventType == .processSpawn &&
            ev.ppid != nil && ev.ppid != 0 &&
            suspiciousProcessNames.contains(where: { (ev.processName ?? "").lowercased().contains($0) })
        }
        if !childProcessEvents.isEmpty {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-PROC-005",
                    ruleName: "UnexpectedChildProcess",
                    severity: .medium,
                    category: .processAnomaly,
                    triggeredEventIDs: childProcessEvents.map { $0.id },
                    matchedIndicator: "Figli sospetti individuati: \(childProcessEvents.compactMap { $0.processName }.joined(separator: ", "))",
                    recommendedAction: .requireUserConfirmation
                )
            )
        }
        
        // 3. Valutazione RULE-PERSIST-002: UnauthorizedPersistenceWrite
        let persistenceEvents = events.filter { ev in
            ev.eventType == .persistenceWrite ||
            (ev.eventType == .fileIO && (
                ev.filePath?.contains("/etc/systemd/") == true ||
                ev.filePath?.contains("/etc/cron") == true ||
                ev.filePath?.contains("/etc/init.d/") == true ||
                ev.filePath?.contains("/etc/rc.local") == true
            ))
        }
        if !persistenceEvents.isEmpty {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-PERSIST-002",
                    ruleName: "UnauthorizedPersistenceWrite",
                    severity: .critical,
                    category: .persistence,
                    triggeredEventIDs: persistenceEvents.map { $0.id },
                    matchedIndicator: "Scrittura in directory di persistenza privilegiata: \(persistenceEvents.compactMap { $0.filePath ?? $0.persistenceTarget }.joined(separator: ", "))",
                    recommendedAction: .stopAuthorizedVM
                )
            )
        }
        
        // 4. Valutazione RULE-NET-003: ViolatedIsolationEgressAttempt
        let networkEvents = events.filter { ev in
            ev.eventType == .networkAttempt &&
            ev.destinationAddress != nil &&
            ev.destinationAddress != "127.0.0.1" &&
            ev.destinationAddress != "::1"
        }
        if !networkEvents.isEmpty {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-NET-003",
                    ruleName: "ViolatedIsolationEgressAttempt",
                    severity: .critical,
                    category: .networkEgress,
                    triggeredEventIDs: networkEvents.map { $0.id },
                    matchedIndicator: "Tentativi di egress non autorizzati: \(networkEvents.compactMap { "\($0.destinationAddress ?? ""):\($0.destinationPort ?? 0)" }.joined(separator: ", "))",
                    recommendedAction: .stopAuthorizedVM
                )
            )
        }
        
        // 5. Valutazione RULE-HEARTBEAT-000: SensorHeartbeatLoss
        let heartbeats = events.filter { $0.eventType == .sensorHeartbeat }
        let hasRecentHeartbeat = !heartbeats.isEmpty
        // Se ci sono altri eventi ma NESSUN heartbeat, o intervallo scaduto:
        if !events.isEmpty && !hasRecentHeartbeat {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-HEARTBEAT-000",
                    ruleName: "SensorHeartbeatLoss",
                    severity: .high,
                    category: .telemetryHealth,
                    triggeredEventIDs: events.prefix(2).map { $0.id },
                    matchedIndicator: "Heartbeat del sensore guest non pervenuto durante la sessione",
                    recommendedAction: .markMonitoringDegraded
                )
            )
        }
        
        // 6. Valutazione RULE-INJECT-001: HostileLogPromptInjection
        let injectionPatterns = [
            "ignore previous instructions",
            "system override",
            "delete host",
            "rm -rf",
            "curl -s",
            "drop table",
            "disable security rules"
        ]
        let injectionEvents = events.filter { ev in
            guard let raw = ev.rawPayload?.lowercased() else { return false }
            return injectionPatterns.contains(where: { raw.contains($0) })
        }
        if !injectionEvents.isEmpty {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-INJECT-001",
                    ruleName: "HostileLogPromptInjection",
                    severity: .low,
                    category: .antiTamper,
                    triggeredEventIDs: injectionEvents.map { $0.id },
                    matchedIndicator: "Pattern ostile identificato come DATO PURO: \(injectionEvents.count) righe isolate",
                    recommendedAction: .treatAsDataOnly
                )
            )
        }
        
        // 7. Valutazione RULE-CRYPTO-009: RapidFileEntropyShift
        let cryptoExtEvents = events.filter { ev in
            guard let path = ev.filePath?.lowercased() else { return false }
            return path.hasSuffix(".locked") || path.hasSuffix(".enc") || path.hasSuffix(".crypto") || path.hasSuffix(".crypted")
        }
        if cryptoExtEvents.count >= 3 {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-CRYPTO-009",
                    ruleName: "RapidFileEntropyShift",
                    severity: .critical,
                    category: .behavioralIO,
                    triggeredEventIDs: cryptoExtEvents.map { $0.id },
                    matchedIndicator: "Rilevate \(cryptoExtEvents.count) modifiche a estensioni tipiche di cifratura malevola",
                    recommendedAction: .stopAuthorizedVM
                )
            )
        }
        
        // 8. Se nessun allarme medio o critico è scattato e c'è almeno un evento di processo valido
        if matches.isEmpty && !events.isEmpty && hasRecentHeartbeat {
            matches.append(
                RuleEvaluationMatch(
                    ruleId: "RULE-SAFE-001",
                    ruleName: "StandardProcessLifecycle",
                    severity: .info,
                    category: .processAnomaly,
                    triggeredEventIDs: events.map { $0.id },
                    matchedIndicator: "Nessun indicatore malevolo o anomalo rilevato nella sequenza",
                    recommendedAction: .logAndMonitor
                )
            )
        }
        
        return matches
    }
    
    /// Determina la classificazione finale del report in base ai match di regole
    public func classify(matches: [RuleEvaluationMatch]) -> (classification: AnalysisClassification, confidence: Double, summary: String) {
        if matches.contains(where: { $0.ruleId == "RULE-HEARTBEAT-000" }) {
            return (
                .unverifiable,
                0.20,
                "Monitoraggio degradato: assenza di heartbeat del sensore. Policy Fail-Closed: esito non verificabile."
            )
        }
        
        if matches.contains(where: { $0.severity == .critical }) {
            return (
                .detected,
                0.96,
                "Rilevato comportamento malevolo critico che richiede contenimento immediato (arresto della VM)."
            )
        }
        
        if matches.contains(where: { $0.severity == .medium || $0.severity == .high }) {
            return (
                .suspicious,
                0.78,
                "Rilevata attività anomala/sospetta (burst di scrittura o spawn di processi inattesi)."
            )
        }
        
        return (
            .notDetected,
            0.92,
            "Nessun indicatore malevolo rilevato entro i parametri di osservazione della sessione."
        )
    }
}
