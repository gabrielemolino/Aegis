import Foundation

public final class SystemCheckService: Sendable {
    public static let shared = SystemCheckService()
    
    public init() {}
    
    /// Rileva l'architettura della macchina (Apple Silicon arm64)
    public func detectArchitecture() -> (isAppleSilicon: Bool, archName: String) {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let isARM = identifier.contains("arm64")
        return (isAppleSilicon: isARM, archName: identifier.isEmpty ? "arm64 (Apple Silicon)" : identifier)
    }
    
    /// Rileva versione di macOS
    public func detectMacOSVersion() -> (versionString: String, isCompatible: Bool) {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let str = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        // Compatibile con macOS 14 (Sonoma) e successivi (inclusi 15 Sequoia o versioni future)
        let isCompatible = version.majorVersion >= 14
        return (versionString: str, isCompatible: isCompatible)
    }
    
    /// Verifica la presenza dell'applicazione UTM.app nel sistema
    public func checkUTMInstallation() -> (isInstalled: Bool, path: String?, isCliAvailable: Bool, cliPath: String?) {
        let possibleAppPaths = [
            "/Applications/UTM.app",
            "\(NSHomeDirectory())/Applications/UTM.app"
        ]
        
        var foundAppPath: String? = nil
        for path in possibleAppPaths {
            if FileManager.default.fileExists(atPath: path) {
                foundAppPath = path
                break
            }
        }
        
        let possibleCliPaths = [
            "/Applications/UTM.app/Contents/MacOS/utmctl",
            "/usr/local/bin/utmctl",
            "/opt/homebrew/bin/utmctl"
        ]
        
        var foundCliPath: String? = nil
        for path in possibleCliPaths {
            if FileManager.default.fileExists(atPath: path) {
                foundCliPath = path
                break
            }
        }
        
        return (
            isInstalled: foundAppPath != nil,
            path: foundAppPath,
            isCliAvailable: foundCliPath != nil,
            cliPath: foundCliPath
        )
    }
    
    /// Esegue il controllo completo dei prerequisiti
    public func inspectEnvironment() -> VMPrerequisites {
        let arch = detectArchitecture()
        let os = detectMacOSVersion()
        let utm = checkUTMInstallation()
        
        // Nella v0.1 la VM autorizzata non viene creata automaticamente senza consenso:
        // Se UTM è installato, lo stato è "Configurazione richiesta", non "Verificata"
        let isConfigured = false
        
        return VMPrerequisites(
            isAppleSilicon: arch.isAppleSilicon,
            architectureName: arch.archName,
            macOSVersion: os.versionString,
            isMacOSCompatible: os.isCompatible,
            isUTMInstalled: utm.isInstalled,
            utmPath: utm.path,
            isUtmCliAvailable: utm.isCliAvailable,
            utmCliPath: utm.cliPath,
            authorizedVMName: "SentinelAI-Ubuntu-Guest",
            isVMConfigured: isConfigured
        )
    }
}
