import Testing
import Foundation
@testable import SentinelAI

@Suite("Aegis End-to-End & Localization Integration Tests (v0.7)")
struct AegisEndToEndTests {
    
    @Test("E2E Pipeline Completa: Da ispezione statica ad arresto VM, triage LLM ed export log")
    @MainActor
    func testCompleteAegisPipeline() async {
        let appState = AppState.shared
        let engine = SecurityEngine.shared
        let ingestionService = TelemetryIngestionService.shared
        let auditLogger = AuditLogger.shared
        let llmService = LocalLLMService.shared
        
        // 1. Ispezione Statica File (Calcolo crittografico SHA-256 senza esecuzione host)
        let sampleContent = "Aegis E2E Mock Payload: \(UUID().uuidString)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("aegis_e2e_test_sample.sh")
        try? sampleContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        appState.selectFile(url: tempURL)
        let target = appState.targetFile
        #expect(target != nil)
        #expect(target?.sha256.isEmpty == false)
        #expect(target?.name == "aegis_e2e_test_sample.sh")
        
        // 2. Preflight e Hardening Checklist (Fail-Closed)
        appState.prerequisites.isAppleSilicon = true
        appState.prerequisites.isMacOSCompatible = true
        appState.prerequisites.isUTMInstalled = true
        appState.isolationChecklist.vmNetworkDisconnected = true
        appState.isolationChecklist.hostFolderSharingDisabled = true
        appState.isolationChecklist.sharedClipboardDisabled = true
        appState.isolationChecklist.noUsbPassthrough = true
        appState.isolationChecklist.cleanSnapshotVerified = true
        appState.vmStatus = .verified
        
        let preflightOk = appState.performPreflight()
        #expect(preflightOk == true)
        
        // 3. Ingestione Telemetria Reale dal Guest (Scenario Network Egress Critico)
        let netEvents = [
            TelemetryEvent(
                id: "EVT-E2E-HB-01",
                timestamp: Date(),
                eventType: .sensorHeartbeat
            ),
            TelemetryEvent(
                id: "EVT-E2E-SPAWN",
                timestamp: Date().addingTimeInterval(0.1),
                eventType: .processSpawn,
                pid: 8001,
                ppid: 1,
                processName: "backdoor_agent",
                commandLine: "./backdoor_agent --connect 85.239.242.18:443"
            ),
            TelemetryEvent(
                id: "EVT-E2E-NET-01",
                timestamp: Date().addingTimeInterval(0.2),
                eventType: .networkAttempt,
                destinationAddress: "85.239.242.18",
                destinationPort: 443,
                protocolName: "tcp",
                isUntrustedData: true
            )
        ]
        
        let ingestionResult = ingestionService.evaluateIngestedTelemetry(events: netEvents)
        #expect(ingestionResult.validEventsCount == 3)
        #expect(ingestionResult.classification == .detected)
        
        // 4. Esecuzione Analisi Deterministica con Contenimento VM
        let report = engine.runAnalysis(from: ingestionResult, for: target!, vmName: "SentinelAI-Ubuntu-Guest")
        #expect(report.classification == .detected)
        #expect(report.actionsExecuted.contains { $0.actionType.contains("Arresto immediato VM") })
        
        // 5. Triage Semantico LLM (qwen2.5-coder:3b) con MITRE ATT&CK
        #expect(report.llmAnalysis != nil)
        #expect(report.llmAnalysis?.modelName.contains("qwen2.5-coder:3b") == true)
        #expect(report.llmAnalysis?.mitreAttackTechniques.contains { $0.contains("T1071.001") } == true)
        #expect(report.llmAnalysis?.recommendedAction == .stopAuthorizedVM)
        
        // 6. Esportazione Audit Log
        let jsonExport = auditLogger.exportAsJSON()
        #expect(!jsonExport.isEmpty)
        #expect(jsonExport.contains("SecurityEngine"))
    }
    
    @Test("Bilinguismo Reattivo (Italiano & Inglese): Commutazione lingua istantanea e coerenza dizionario")
    @MainActor
    func testReactiveLocalization() {
        let i18n = LocalizationManager.shared
        
        // Test Italiano
        i18n.setLanguage(.italian)
        #expect(i18n.currentLanguage == .italian)
        #expect(i18n.t("app_name") == "Aegis")
        #expect(i18n.t("tab_overview") == "Panoramica")
        #expect(i18n.t("tab_analysis") == "Analisi")
        #expect(i18n.t("tab_settings") == "Impostazioni")
        #expect(i18n.t("disclaimer_title").contains("Dichiarazione di Non Responsabilità"))
        
        // Test Inglese
        i18n.setLanguage(.english)
        #expect(i18n.currentLanguage == .english)
        #expect(i18n.t("app_name") == "Aegis")
        #expect(i18n.t("tab_overview") == "Overview")
        #expect(i18n.t("tab_analysis") == "Analysis")
        #expect(i18n.t("tab_settings") == "Settings")
        #expect(i18n.t("disclaimer_title").contains("Limitation of Liability"))
        
        // Ripristino Italiano come default
        i18n.setLanguage(.italian)
    }
    
    @Test("Clausola Esonero di Responsabilità: Presenza e completezza del testo legale in entrambe le lingue")
    @MainActor
    func testLegalDisclaimerIntegrity() {
        let i18n = LocalizationManager.shared
        
        // Verifica clausola in Italiano
        i18n.setLanguage(.italian)
        let italianText = i18n.t("disclaimer_summary")
        #expect(italianText.contains("declina") || italianText.contains("declinano"))
        #expect(italianText.contains("responsabilità"))
        #expect(italianText.contains("danno"))
        #expect(italianText.contains("esclusiva responsabilità") || italianText.contains("proprio rischio"))
        
        // Verifica clausola in Inglese
        i18n.setLanguage(.english)
        let englishText = i18n.t("disclaimer_summary")
        #expect(englishText.contains("disclaim") || englishText.contains("liability"))
        #expect(englishText.contains("damages") || englishText.contains("risk"))
        #expect(englishText.contains("sole responsibility") || englishText.contains("own risk"))
        
        i18n.setLanguage(.italian)
    }
}
