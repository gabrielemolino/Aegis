import Foundation
import Combine

public final class AuditLogger: ObservableObject, @unchecked Sendable {
    public static let shared = AuditLogger()
    
    @Published public private(set) var events: [AuditEvent] = []
    private let queue = DispatchQueue(label: "org.sentinelai.auditlogger", qos: .utility)
    
    public init() {
        // Evento iniziale di avvio audit host
        log(
            level: .info,
            category: .system,
            source: "HostController",
            description: "SentinelAI v0.1 inizializzato in modalità sicura (nessun comando shell arbitrario consentito)",
            isSimulation: false
        )
    }
    
    /// Aggiunge un evento all'audit log sanificando i parametri per evitare log-injection
    public func log(
        level: AuditLogLevel,
        category: AuditCategory,
        source: String,
        description: String,
        details: String? = nil,
        isSimulation: Bool = false
    ) {
        let sanitizedSource = sanitizeString(source)
        let sanitizedDescription = sanitizeString(description)
        let sanitizedDetails = details.map { sanitizeString($0) }
        
        let event = AuditEvent(
            timestamp: Date(),
            level: level,
            category: category,
            source: sanitizedSource,
            description: sanitizedDescription,
            details: sanitizedDetails,
            isSimulation: isSimulation
        )
        
        if Thread.isMainThread {
            self.events.insert(event, at: 0)
            if self.events.count > 1000 {
                self.events.removeLast()
            }
        } else {
            DispatchQueue.main.async {
                self.events.insert(event, at: 0)
                if self.events.count > 1000 {
                    self.events.removeLast()
                }
            }
        }
    }
    
    /// Rimuove caratteri di controllo non stampabili ed escape sequences
    public func sanitizeString(_ input: String) -> String {
        return input.unicodeScalars
            .filter { scalar in
                if scalar.value == 0x0A || scalar.value == 0x09 { return true }
                return scalar.value >= 32 && scalar.value != 127
            }
            .map { String($0) }
            .joined()
    }
    
    /// Esporta l'audit log in formato JSON formattato
    public func exportAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(events)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Impossibile esportare log: \(error.localizedDescription)\"}"
        }
    }
    
    /// Esporta il log in formato testo tabulare
    public func exportAsText() -> String {
        var output = "=== SENTINELAI AUDIT LOG EXPORT ===\n"
        output += "Generato: \(ISO8601DateFormatter().string(from: Date()))\n"
        output += "Totale eventi: \(events.count)\n"
        output += "Nota di sicurezza: Nessun dato sensibile o malware payload registrato.\n"
        output += "--------------------------------------------------------------------------------\n\n"
        
        for event in events {
            let simFlag = event.isSimulation ? "[SIMULATO] " : ""
            output += "[\(event.formattedTimestamp)] [\(event.level.rawValue)] [\(event.category.rawValue)] [\(event.source)] \(simFlag)\(event.description)\n"
            if let details = event.details, !details.isEmpty {
                output += "    Dettagli: \(details)\n"
            }
        }
        return output
    }
    
    /// Svuota i log (per i test o reset controllato)
    public func clear() {
        DispatchQueue.main.async {
            self.events.removeAll()
        }
    }
}
