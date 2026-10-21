import Foundation

/// Tipologia di evento di telemetria intercettato nel guest di analisi
public enum TelemetryEventType: String, Codable, Sendable, CaseIterable {
    case processSpawn = "PROCESS_SPAWN"
    case fileIO = "FILE_IO"
    case networkAttempt = "NETWORK_ATTEMPT"
    case persistenceWrite = "PERSISTENCE_WRITE"
    case sensorHeartbeat = "SENSOR_HEARTBEAT"
    case logMessage = "LOG_MESSAGE"
}

/// Operazione di I/O su filesystem
public enum FileOperationType: String, Codable, Sendable {
    case create = "CREATE"
    case write = "WRITE"
    case delete = "DELETE"
    case chmod = "CHMOD"
    case rename = "RENAME"
}

/// Record di evento di telemetria (prodotto dal sensore guest o da fixture sintetica)
public struct TelemetryEvent: Identifiable, Codable, Sendable, Equatable {
    public var id: String
    public var timestamp: Date
    public var source: String
    public var eventType: TelemetryEventType
    
    // Process context
    public var pid: Int?
    public var ppid: Int?
    public var processName: String?
    public var commandLine: String?
    
    // File I/O context
    public var filePath: String?
    public var fileOperation: FileOperationType?
    public var byteCount: Int?
    
    // Network context
    public var destinationAddress: String?
    public var destinationPort: Int?
    public var protocolName: String?
    
    // Persistence context
    public var persistenceTarget: String?
    
    // Raw log or untrusted string data (e.g., prompt injection strings)
    public var rawPayload: String?
    
    // Flag che marca esplicitamente il payload come DATO PURO (mai eseguibile come istruzione)
    public var isUntrustedData: Bool
    
    public init(
        id: String,
        timestamp: Date = Date(),
        source: String = "guest.sensor.fixture",
        eventType: TelemetryEventType,
        pid: Int? = nil,
        ppid: Int? = nil,
        processName: String? = nil,
        commandLine: String? = nil,
        filePath: String? = nil,
        fileOperation: FileOperationType? = nil,
        byteCount: Int? = nil,
        destinationAddress: String? = nil,
        destinationPort: Int? = nil,
        protocolName: String? = nil,
        persistenceTarget: String? = nil,
        rawPayload: String? = nil,
        isUntrustedData: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.eventType = eventType
        self.pid = pid
        self.ppid = ppid
        self.processName = processName
        self.commandLine = commandLine
        self.filePath = filePath
        self.fileOperation = fileOperation
        self.byteCount = byteCount
        self.destinationAddress = destinationAddress
        self.destinationPort = destinationPort
        self.protocolName = protocolName
        self.persistenceTarget = persistenceTarget
        self.rawPayload = rawPayload
        self.isUntrustedData = isUntrustedData
    }
    
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
