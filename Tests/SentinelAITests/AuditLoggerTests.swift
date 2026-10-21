import Testing
import Foundation
@testable import SentinelAI

@Suite("AuditLogger Tests")
struct AuditLoggerTests {
    
    @Test("Verifica sanificazione stringhe contro log injection")
    func testSanitization() {
        let logger = AuditLogger.shared
        
        let hostileString = "Normale\u{0000}\u{001B}[31mRosso\u{0007}Fine"
        let sanitized = logger.sanitizeString(hostileString)
        
        // Nessun carattere di controllo non stampabile deve rimanere
        #expect(!sanitized.contains("\u{0000}"))
        #expect(!sanitized.contains("\u{001B}"))
        #expect(!sanitized.contains("\u{0007}"))
        #expect(sanitized.contains("Normale"))
        #expect(sanitized.contains("Fine"))
    }
    
    @Test("Verifica esportazione in formato JSON valido")
    func testJSONExport() throws {
        let logger = AuditLogger.shared
        logger.log(
            level: .info,
            category: .system,
            source: "TestRunner",
            description: "Evento di test JSON",
            details: "Dettagli verificati"
        )
        
        let jsonString = logger.exportAsJSON()
        #expect(!jsonString.isEmpty)
        
        // Verifica che sia parsabile come JSON
        let data = Data(jsonString.utf8)
        let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(jsonArray != nil)
    }
    
    @Test("Verifica esportazione in formato testo")
    func testTextExport() {
        let logger = AuditLogger.shared
        let text = logger.exportAsText()
        
        #expect(text.contains("SENTINELAI AUDIT LOG EXPORT"))
        #expect(text.contains("Nessun dato sensibile o malware payload registrato"))
    }
}
