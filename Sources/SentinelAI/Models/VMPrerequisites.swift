import Foundation

/// Dettaglio prerequisiti di sistema e ambiente isolato UTM
public struct VMPrerequisites: Codable, Sendable, Equatable {
    public var isAppleSilicon: Bool
    public var architectureName: String
    public var macOSVersion: String
    public var isMacOSCompatible: Bool
    public var isUTMInstalled: Bool
    public var utmPath: String?
    public var isUtmCliAvailable: Bool
    public var utmCliPath: String?
    public var authorizedVMName: String
    public var isVMConfigured: Bool
    
    public init(
        isAppleSilicon: Bool = false,
        architectureName: String = "unknown",
        macOSVersion: String = "unknown",
        isMacOSCompatible: Bool = false,
        isUTMInstalled: Bool = false,
        utmPath: String? = nil,
        isUtmCliAvailable: Bool = false,
        utmCliPath: String? = nil,
        authorizedVMName: String = "SentinelAI-Sandbox-Ubuntu",
        isVMConfigured: Bool = false
    ) {
        self.isAppleSilicon = isAppleSilicon
        self.architectureName = architectureName
        self.macOSVersion = macOSVersion
        self.isMacOSCompatible = isMacOSCompatible
        self.isUTMInstalled = isUTMInstalled
        self.utmPath = utmPath
        self.isUtmCliAvailable = isUtmCliAvailable
        self.utmCliPath = utmCliPath
        self.authorizedVMName = authorizedVMName
        self.isVMConfigured = isVMConfigured
    }
    
    public var isReadyForAnalysis: Bool {
        isAppleSilicon && isMacOSCompatible && isUTMInstalled && isVMConfigured
    }
}
