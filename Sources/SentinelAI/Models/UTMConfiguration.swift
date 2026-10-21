import Foundation

/// Dettaglio della configurazione e dello stato della VM UTM autorizzata
public struct UTMVMConfig: Codable, Sendable, Equatable {
    public var vmName: String
    public var guestOS: String
    public var isNetworkIsolated: Bool
    public var isFolderSharingDisabled: Bool
    public var isClipboardSharingDisabled: Bool
    public var isUsbPassthroughDisabled: Bool
    public var hasCleanSnapshot: Bool
    public var snapshotName: String
    public var lastAttestationDate: Date?
    
    public init(
        vmName: String = "SentinelAI-Ubuntu-Guest",
        guestOS: String = "Ubuntu 24.04 LTS (ARM64)",
        isNetworkIsolated: Bool = true,
        isFolderSharingDisabled: Bool = true,
        isClipboardSharingDisabled: Bool = true,
        isUsbPassthroughDisabled: Bool = true,
        hasCleanSnapshot: Bool = false,
        snapshotName: String = "clean-baseline",
        lastAttestationDate: Date? = nil
    ) {
        self.vmName = vmName
        self.guestOS = guestOS
        self.isNetworkIsolated = isNetworkIsolated
        self.isFolderSharingDisabled = isFolderSharingDisabled
        self.isClipboardSharingDisabled = isClipboardSharingDisabled
        self.isUsbPassthroughDisabled = isUsbPassthroughDisabled
        self.hasCleanSnapshot = hasCleanSnapshot
        self.snapshotName = snapshotName
        self.lastAttestationDate = lastAttestationDate
    }
    
    /// Tutti i 5 criteri di isolamento rigoroso devono essere soddisfatti
    public var isFullyHardened: Bool {
        isNetworkIsolated &&
        isFolderSharingDisabled &&
        isClipboardSharingDisabled &&
        isUsbPassthroughDisabled &&
        hasCleanSnapshot
    }
    
    /// Conteggio dei criteri conformi rispetto al totale (su 5)
    public var complianceScore: (passed: Int, total: Int) {
        var passed = 0
        if isNetworkIsolated { passed += 1 }
        if isFolderSharingDisabled { passed += 1 }
        if isClipboardSharingDisabled { passed += 1 }
        if isUsbPassthroughDisabled { passed += 1 }
        if hasCleanSnapshot { passed += 1 }
        return (passed, 5)
    }
}

/// Stato operativo della VM UTM rilevato dal controller host
public enum UTMVMExecutionState: String, Codable, Sendable {
    case stopped = "Arrestata (Disattivata)"
    case running = "In esecuzione"
    case suspended = "Sospesa (Stato compromesso memorizzato)"
    case unknown = "Non verificabile (UTM chiuso o non responsivo)"
    
    public var isSafeForAnalysisStart: Bool {
        // L'analisi può partire solo se la VM è pulita e spenta (da avviare) o pronta da snapshot
        self == .stopped
    }
}

/// Regola esplicita sulle procedure di bonifica della Sandbox
public struct UTMBonificaPolicy: Sendable {
    public static let suspensionCaveat: String =
        "ATTENZIONE: La sospensione (Pause/Suspend) della VM congela l'esecuzione in memoria e preserva lo stato compromesso. NON costituisce una bonifica. Per ripristinare la sicurezza è obbligatorio eseguire il rollback a uno snapshot pulito ('clean-baseline')."
    
    public static let rollbackRequirement: String =
        "Dopo ogni esecuzione o arresto di contenimento, la VM deve essere ripristinata dallo snapshot 'clean-baseline'. È fatto divieto assoluto di riavviare la macchina virtuale nello stato post-infezione."
}
