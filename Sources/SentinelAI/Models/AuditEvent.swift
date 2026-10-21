import Foundation

public enum AuditLogLevel: String, Codable, Sendable, CaseIterable {
    case info = "INFO"
    case warning = "WARNING"
    case critical = "CRITICAL"
}

public enum AuditCategory: String, Codable, Sendable, CaseIterable {
    case all = "Tutti"
    case system = "Sistema & Prerequisiti"
    case preflight = "Preflight & Isolamento"
    case analysis = "Analisi Comportamentale"
    case containment = "Contenimento Host"
    case rules = "Motore Regole"
}

/// Record immutabile di audit log dell'applicazione
public struct AuditEvent: Identifiable, Codable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var level: AuditLogLevel
    public var category: AuditCategory
    public var source: String
    public var description: String
    public var details: String?
    public var isSimulation: Bool
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: AuditLogLevel,
        category: AuditCategory,
        source: String,
        description: String,
        details: String? = nil,
        isSimulation: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.source = source
        self.description = description
        self.details = details
        self.isSimulation = isSimulation
    }
    
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
