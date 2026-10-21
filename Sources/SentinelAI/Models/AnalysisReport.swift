import Foundation

/// Regola deterministica attivata durante l'analisi
public struct RuleTrigger: Identifiable, Codable, Sendable, Equatable {
    public var id: String
    public var ruleName: String
    public var severity: RuleSeverity
    public var description: String
    public var matchedIndicator: String
    
    public init(id: String, ruleName: String, severity: RuleSeverity, description: String, matchedIndicator: String) {
        self.id = id
        self.ruleName = ruleName
        self.severity = severity
        self.description = description
        self.matchedIndicator = matchedIndicator
    }
}

public enum RuleSeverity: String, Codable, Sendable {
    case info = "Info"
    case low = "Basso Rischio"
    case medium = "Medio Rischio"
    case high = "Alto Rischio"
    case critical = "Critico"
}

/// Azione di contenimento eseguita dal controller
public struct ContainmentAction: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var actionType: String
    public var targetVM: String
    public var status: String
    public var timestamp: Date
    public var isSimulation: Bool
    
    public init(
        id: UUID = UUID(),
        actionType: String,
        targetVM: String,
        status: String,
        timestamp: Date = Date(),
        isSimulation: Bool = true
    ) {
        self.id = id
        self.actionType = actionType
        self.targetVM = targetVM
        self.status = status
        self.timestamp = timestamp
        self.isSimulation = isSimulation
    }
}

/// Metadati sicuri del file selezionato per l'analisi
public struct SafeTargetFile: Codable, Sendable, Equatable {
    public var name: String
    public var path: String
    public var sizeBytes: Int64
    public var sha256: String
    public var detectedMimeType: String
    
    public init(name: String, path: String, sizeBytes: Int64, sha256: String, detectedMimeType: String = "application/octet-stream") {
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.sha256 = sha256
        self.detectedMimeType = detectedMimeType
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }
}

/// Report strutturato finale di analisi
public struct AnalysisReport: Identifiable, Codable, Sendable {
    public var id: UUID
    public var date: Date
    public var targetFile: SafeTargetFile
    public var classification: AnalysisClassification
    public var confidenceScore: Double
    public var summary: String
    public var evidence: [String]
    public var rulesTriggered: [RuleTrigger]
    public var actionsExecuted: [ContainmentAction]
    public var limitations: [String]
    public var isSimulatedDemo: Bool
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        targetFile: SafeTargetFile,
        classification: AnalysisClassification,
        confidenceScore: Double,
        summary: String,
        evidence: [String],
        rulesTriggered: [RuleTrigger],
        actionsExecuted: [ContainmentAction],
        limitations: [String],
        isSimulatedDemo: Bool = true
    ) {
        self.id = id
        self.date = date
        self.targetFile = targetFile
        self.classification = classification
        self.confidenceScore = confidenceScore
        self.summary = summary
        self.evidence = evidence
        self.rulesTriggered = rulesTriggered
        self.actionsExecuted = actionsExecuted
        self.limitations = limitations
        self.isSimulatedDemo = isSimulatedDemo
    }
}
