import Foundation

/// Categoria di regola deterministica
public enum RuleCategory: String, Codable, Sendable, CaseIterable {
    case processAnomaly = "Processi & Figli Inattesi"
    case behavioralIO = "Comportamento I/O Filesystem"
    case persistence = "Tentativi di Persistenza"
    case networkEgress = "Violazioni Isolamento Rete"
    case antiTamper = "Protezione Log & Anti-Tamper"
    case telemetryHealth = "Integrità Sensore & Heartbeat"
}

/// Azione di risposta raccomandata (rigorosamente appartenente ad una allowlist chiusa)
public enum RecommendedContainmentAction: String, Codable, Sendable {
    case logAndMonitor = "LOG_AND_MONITOR"
    case raiseWarningAlert = "RAISE_WARNING_ALERT"
    case requireUserConfirmation = "REQUIRE_USER_CONFIRMATION"
    case stopAuthorizedVM = "STOP_AUTHORIZED_VM"
    case markMonitoringDegraded = "MARK_MONITORING_DEGRADED"
    case treatAsDataOnly = "TREAT_AS_DATA_ONLY"
    
    public var userDescription: String {
        switch self {
        case .logAndMonitor:
            return "Registra l'evento nell'audit log e mantieni il monitoraggio."
        case .raiseWarningAlert:
            return "Genera avviso di sicurezza e notifica l'operatore nella UI."
        case .requireUserConfirmation:
            return "Richiedi conferma prima di procedere con l'esecuzione."
        case .stopAuthorizedVM:
            return "Arresta immediatamente la sola VM autorizzata (Contenimento d'emergenza)."
        case .markMonitoringDegraded:
            return "Segnala stato di monitoraggio degradato; applica policy prudente fail-closed."
        case .treatAsDataOnly:
            return "Tratta il payload come dato passivo; vieta qualsiasi esecuzione come comando."
        }
    }
}

/// Definizione statica versionata di una regola deterministica
public struct RuleDefinition: Identifiable, Codable, Sendable, Equatable {
    public var id: String
    public var name: String
    public var category: RuleCategory
    public var severity: RuleSeverity
    public var description: String
    public var version: String
    public var recommendedAction: RecommendedContainmentAction
    
    public init(
        id: String,
        name: String,
        category: RuleCategory,
        severity: RuleSeverity,
        description: String,
        version: String = "v0.3.0",
        recommendedAction: RecommendedContainmentAction
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.severity = severity
        self.description = description
        self.version = version
        self.recommendedAction = recommendedAction
    }
}

/// Risultato di attivazione (match) di una regola su uno o più eventi di telemetria
public struct RuleEvaluationMatch: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var ruleId: String
    public var ruleName: String
    public var severity: RuleSeverity
    public var category: RuleCategory
    public var triggeredEventIDs: [String] // Obbligo specifica sez. 11: riferimento ad ID evento reali
    public var matchedIndicator: String
    public var recommendedAction: RecommendedContainmentAction
    public var timestamp: Date
    
    public init(
        id: UUID = UUID(),
        ruleId: String,
        ruleName: String,
        severity: RuleSeverity,
        category: RuleCategory,
        triggeredEventIDs: [String],
        matchedIndicator: String,
        recommendedAction: RecommendedContainmentAction,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.ruleId = ruleId
        self.ruleName = ruleName
        self.severity = severity
        self.category = category
        self.triggeredEventIDs = triggeredEventIDs
        self.matchedIndicator = matchedIndicator
        self.recommendedAction = recommendedAction
        self.timestamp = timestamp
    }
}
