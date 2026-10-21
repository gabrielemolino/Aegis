import Foundation

/// Risultato dell'ingestione e valutazione della telemetria guest
public struct IngestionAnalysisResult: Sendable {
    public let totalEventsCount: Int
    public let validEventsCount: Int
    public let corruptedLinesCount: Int
    public let events: [TelemetryEvent]
    public let ruleMatches: [RuleEvaluationMatch]
    public let classification: AnalysisClassification
    public let confidenceScore: Double
    public let summary: String
    
    public init(
        totalEventsCount: Int,
        validEventsCount: Int,
        corruptedLinesCount: Int,
        events: [TelemetryEvent],
        ruleMatches: [RuleEvaluationMatch],
        classification: AnalysisClassification,
        confidenceScore: Double,
        summary: String
    ) {
        self.totalEventsCount = totalEventsCount
        self.validEventsCount = validEventsCount
        self.corruptedLinesCount = corruptedLinesCount
        self.events = events
        self.ruleMatches = ruleMatches
        self.classification = classification
        self.confidenceScore = confidenceScore
        self.summary = summary
    }
}

/// Servizio di parsing e ingestione sicura della telemetria proveniente dal sensore guest
public final class TelemetryIngestionService: Sendable {
    public static let shared = TelemetryIngestionService()
    
    private let auditLogger = AuditLogger.shared
    private let ruleEngine = RuleEngineService.shared
    
    public init() {}
    
    /// Effettua il parsing sicuro di una stringa JSON Lines (.jsonl)
    /// Garantisce resilienza a linee corrotte o incomplete senza sollevare eccezioni bloccanti.
    public func parseEvents(from jsonlString: String) -> (events: [TelemetryEvent], corruptedCount: Int) {
        var events: [TelemetryEvent] = []
        var corruptedCount = 0
        
        let lines = jsonlString.components(separatedBy: .newlines)
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let str = try container.decode(String.self)
            
            let isoFormatterWithFraction = ISO8601DateFormatter()
            isoFormatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatterWithFraction.date(from: str) {
                return date
            }
            
            let isoFormatterStandard = ISO8601DateFormatter()
            isoFormatterStandard.formatOptions = [.withInternetDateTime]
            if let date = isoFormatterStandard.date(from: str) {
                return date
            }
            
            // Fallback: DateFormatter standard
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            if let date = df.date(from: str) {
                return date
            }
            return Date()
        }
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            guard let data = trimmed.data(using: .utf8) else {
                corruptedCount += 1
                continue
            }
            
            do {
                var event = try decoder.decode(TelemetryEvent.self, from: data)
                // Garanzia non-negoziabile: ogni evento proveniente dal guest è marcato DATO NON ATTENDIBILE
                event.isUntrustedData = true
                events.append(event)
            } catch {
                corruptedCount += 1
                // Log diagnostico senza interrompere il flusso
                auditLogger.log(
                    level: .warning,
                    category: .rules,
                    source: "TelemetryIngestionService",
                    description: "Linea telemetria guest non conforme ignorata (riga \(index + 1))",
                    details: "Errore parsing JSON: \(error.localizedDescription)",
                    isSimulation: false
                )
            }
        }
        
        return (events, corruptedCount)
    }
    
    /// Legge e analizza un file di telemetria da URL
    public func parseEvents(from url: URL) throws -> (events: [TelemetryEvent], corruptedCount: Int) {
        let content = try String(contentsOf: url, encoding: .utf8)
        let result = parseEvents(from: content)
        
        auditLogger.log(
            level: .info,
            category: .analysis,
            source: "TelemetryIngestionService",
            description: "Importata telemetria guest da file: \(url.lastPathComponent)",
            details: "Eventi validi: \(result.events.count), Linee scartate: \(result.corruptedCount)",
            isSimulation: false
        )
        
        return result
    }
    
    /// Elabora gli eventi ingeriti attraverso il RuleEngine deterministico
    public func evaluateIngestedTelemetry(events: [TelemetryEvent], corruptedCount: Int = 0) -> IngestionAnalysisResult {
        let matches = ruleEngine.evaluate(events: events)
        let classification = ruleEngine.classify(matches: matches)
        
        return IngestionAnalysisResult(
            totalEventsCount: events.count + corruptedCount,
            validEventsCount: events.count,
            corruptedLinesCount: corruptedCount,
            events: events,
            ruleMatches: matches,
            classification: classification.classification,
            confidenceScore: classification.confidence,
            summary: classification.summary
        )
    }
}
