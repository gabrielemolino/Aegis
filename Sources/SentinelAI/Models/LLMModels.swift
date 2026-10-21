import Foundation

/// Stato del runtime LLM locale (Ollama)
public enum LLMServiceStatus: String, Codable, Sendable {
    case ready = "Pronto"
    case offline = "Non attivo (Ollama offline su :11434)"
    case modelMissing = "Modello non scaricato"
    case connecting = "Verifica in corso..."
    case mockActive = "Simulatore Mock Attivo (v0.6)"
    case error = "Errore di connessione"
}

/// Configurazione del client LLM locale
public struct LLMConfiguration: Codable, Sendable, Equatable {
    public var endpointURLString: String
    public var selectedModel: String
    public var timeoutSeconds: TimeInterval
    public var isMockFallbackEnabled: Bool
    public var isLLMAnalysisEnabled: Bool
    
    public init(
        endpointURLString: String = "http://127.0.0.1:11434",
        selectedModel: String = "qwen2.5-coder:3b",
        timeoutSeconds: TimeInterval = 25.0,
        isMockFallbackEnabled: Bool = true,
        isLLMAnalysisEnabled: Bool = true
    ) {
        self.endpointURLString = endpointURLString
        self.selectedModel = selectedModel
        self.timeoutSeconds = timeoutSeconds
        self.isMockFallbackEnabled = isMockFallbackEnabled
        self.isLLMAnalysisEnabled = isLLMAnalysisEnabled
    }
}

/// Report semantico generato dall'LLM locale con schema JSON rigorosamente validato
public struct LLMAnalysisReport: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var modelName: String
    public var timestamp: Date
    public var classification: AnalysisClassification
    public var confidenceScore: Double
    public var summary: String
    public var technicalExplanation: String
    public var mitreAttackTechniques: [String]
    public var referencedEvidenceEventIDs: [String]
    public var recommendedAction: RecommendedContainmentAction
    public var rawResponseText: String?
    public var isMockResponse: Bool
    
    public init(
        id: UUID = UUID(),
        modelName: String,
        timestamp: Date = Date(),
        classification: AnalysisClassification,
        confidenceScore: Double,
        summary: String,
        technicalExplanation: String,
        mitreAttackTechniques: [String],
        referencedEvidenceEventIDs: [String],
        recommendedAction: RecommendedContainmentAction,
        rawResponseText: String? = nil,
        isMockResponse: Bool = false
    ) {
        self.id = id
        self.modelName = modelName
        self.timestamp = timestamp
        self.classification = classification
        self.confidenceScore = confidenceScore
        self.summary = summary
        self.technicalExplanation = technicalExplanation
        self.mitreAttackTechniques = mitreAttackTechniques
        self.referencedEvidenceEventIDs = referencedEvidenceEventIDs
        self.recommendedAction = recommendedAction
        self.rawResponseText = rawResponseText
        self.isMockResponse = isMockResponse
    }
}

/// Struttura JSON attesa dall'LLM locale (schema rigido)
public struct LLMStructuredOutputSchema: Codable, Sendable {
    public let classification: String
    public let confidence: Double
    public let summary: String
    public let technical_explanation: String
    public let mitre_attack_techniques: [String]
    public let evidence_event_ids: [String]
    public let recommended_action: String
    
    public init(
        classification: String,
        confidence: Double,
        summary: String,
        technical_explanation: String,
        mitre_attack_techniques: [String],
        evidence_event_ids: [String],
        recommended_action: String
    ) {
        self.classification = classification
        self.confidence = confidence
        self.summary = summary
        self.technical_explanation = technical_explanation
        self.mitre_attack_techniques = mitre_attack_techniques
        self.evidence_event_ids = evidence_event_ids
        self.recommended_action = recommended_action
    }
}
