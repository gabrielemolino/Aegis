import Foundation

/// Stato di configurazione e isolamento della Sandbox UTM
public enum VMStatus: String, Codable, Sendable {
    case notConfigured = "Non configurata"
    case verified = "Verificata"
    case insecure = "Non sicura"
    case manualVerificationRequired = "Verifica manuale richiesta"
    
    public var description: String {
        self.rawValue
    }
}

/// Livello complessivo di protezione dell'host
public enum OverallProtectionStatus: String, Codable, Sendable {
    case fullyProtected = "Protezione locale verificata"
    case partial = "Protezione parziale / Da verificare"
    case notConfigured = "Non configurata"
    case insecure = "Ambiente non sicuro"
}

/// Esito di classificazione dell'analisi di sicurezza
public enum AnalysisClassification: String, Codable, Sendable {
    case detected = "Rilevato"
    case suspicious = "Sospetto"
    case notDetected = "Non rilevato"
    case unverifiable = "Non verificabile"
    
    public var icon: String {
        switch self {
        case .detected: return "exclamationmark.octagon.fill"
        case .suspicious: return "exclamationmark.triangle.fill"
        case .notDetected: return "checkmark.shield.fill"
        case .unverifiable: return "questionmark.circle.fill"
        }
    }
}

/// Stato corrente del ciclo di analisi
public enum AnalysisRunState: String, Codable, Sendable {
    case idle = "In attesa di selezione file"
    case preflightPending = "Controlli preflight in corso"
    case preflightBlocked = "Avvio bloccato dai controlli preflight"
    case running = "Analisi comportamentale in corso"
    case completed = "Analisi completata"
    case stopped = "Analisi interrotta dall'utente"
}

/// Configurazione dei controlli di isolamento della Sandbox
public struct IsolationChecklist: Codable, Sendable, Equatable {
    public var hostFolderSharingDisabled: Bool
    public var sharedClipboardDisabled: Bool
    public var vmNetworkDisconnected: Bool
    public var cleanSnapshotVerified: Bool
    public var noUsbPassthrough: Bool
    
    public init(
        hostFolderSharingDisabled: Bool = true,
        sharedClipboardDisabled: Bool = true,
        vmNetworkDisconnected: Bool = true,
        cleanSnapshotVerified: Bool = false,
        noUsbPassthrough: Bool = true
    ) {
        self.hostFolderSharingDisabled = hostFolderSharingDisabled
        self.sharedClipboardDisabled = sharedClipboardDisabled
        self.vmNetworkDisconnected = vmNetworkDisconnected
        self.cleanSnapshotVerified = cleanSnapshotVerified
        self.noUsbPassthrough = noUsbPassthrough
    }
    
    /// Tutti i requisiti devono essere verificati per consentire il preflight
    public var allRequirementsMet: Bool {
        hostFolderSharingDisabled &&
        sharedClipboardDisabled &&
        vmNetworkDisconnected &&
        cleanSnapshotVerified &&
        noUsbPassthrough
    }
    
    public var pendingChecksCount: Int {
        var count = 0
        if !hostFolderSharingDisabled { count += 1 }
        if !sharedClipboardDisabled { count += 1 }
        if !vmNetworkDisconnected { count += 1 }
        if !cleanSnapshotVerified { count += 1 }
        if !noUsbPassthrough { count += 1 }
        return count
    }
}
