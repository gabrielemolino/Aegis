import Testing
import Foundation
@testable import SentinelAI

@Suite("SystemCheckService Tests")
struct SystemCheckServiceTests {
    
    @Test("Verifica rilevamento architettura host")
    func testArchitectureDetection() {
        let service = SystemCheckService.shared
        let arch = service.detectArchitecture()
        
        // Su macchine Apple Silicon deve riportare arm64
        #expect(!arch.archName.isEmpty)
        #expect(arch.isAppleSilicon == true)
    }
    
    @Test("Verifica compatibilità versione macOS")
    func testMacOSVersionDetection() {
        let service = SystemCheckService.shared
        let os = service.detectMacOSVersion()
        
        #expect(os.versionString.contains("macOS"))
        #expect(os.isCompatible == true)
    }
    
    @Test("Verifica rilevamento installazione UTM")
    func testUTMDetection() {
        let service = SystemCheckService.shared
        let utm = service.checkUTMInstallation()
        
        // Verifica che il percorso ritornato sia consistente
        if utm.isInstalled {
            #expect(utm.path != nil)
            #expect(FileManager.default.fileExists(atPath: utm.path!))
        }
    }
    
    @Test("Verifica ispezione ambiente iniziale")
    func testInspectEnvironment() {
        let service = SystemCheckService.shared
        let prereqs = service.inspectEnvironment()
        
        #expect(prereqs.isAppleSilicon == true)
        #expect(prereqs.isMacOSCompatible == true)
        #expect(prereqs.authorizedVMName == "SentinelAI-Ubuntu-Guest")
        // Nella v0.1 la VM non è configurata automaticamente per prudenza
        #expect(prereqs.isVMConfigured == false)
    }
}
