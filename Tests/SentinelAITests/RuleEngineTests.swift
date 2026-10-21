import Testing
import Foundation
@testable import SentinelAI

@Suite("Deterministic Rule Engine Tests (v0.3)")
struct RuleEngineTests {
    
    @Test("Catalogo regole: integrità e versionamento del catalogo")
    func testCatalogIntegrity() {
        let engine = RuleEngineService.shared
        #expect(engine.engineVersion.contains("v0.3.0"))
        #expect(!engine.rulesCatalog.isEmpty)
        
        // Verifica che ogni regola abbia ID, nome, severità e azione da allowlist
        for rule in engine.rulesCatalog {
            #expect(!rule.id.isEmpty)
            #expect(!rule.name.isEmpty)
            #expect(!rule.description.isEmpty)
        }
    }
    
    @Test("Regola Clean: ciclo di vita standard viene classificato come Non Rilevato")
    func testCleanProcessFixture() {
        let engine = RuleEngineService.shared
        let events = FixtureDatasets.makeCleanFixture()
        
        let matches = engine.evaluate(events: events)
        let classification = engine.classify(matches: matches)
        
        #expect(matches.count == 1)
        #expect(matches.first?.ruleId == "RULE-SAFE-001")
        #expect(classification.classification == .notDetected)
        #expect(classification.confidence >= 0.90)
    }
    
    @Test("Regola I/O Burst (RULE-IO-014): rileva modifiche frequenti in /tmp con soglia configurabile")
    func testTempBurstThresholdDetection() {
        let engine = RuleEngineService.shared
        let events = FixtureDatasets.makeTempBurstFixture(count: 14)
        
        // 1. Con soglia predefinita (10): deve attivarsi
        let matches = engine.evaluate(events: events, tempWriteThreshold: 10)
        let burstMatch = matches.first(where: { $0.ruleId == "RULE-IO-014" })
        
        #expect(burstMatch != nil)
        #expect(burstMatch?.severity == .medium)
        #expect(burstMatch?.triggeredEventIDs.count == 14)
        #expect(burstMatch?.triggeredEventIDs.contains("EVT-BURST-001") == true)
        #expect(burstMatch?.recommendedAction == .raiseWarningAlert)
        
        let classification = engine.classify(matches: matches)
        #expect(classification.classification == .suspicious)
        
        // 2. Con soglia più alta (20): NON deve attivarsi (soglia configurabile)
        let matchesHighThreshold = engine.evaluate(events: events, tempWriteThreshold: 20)
        #expect(matchesHighThreshold.contains(where: { $0.ruleId == "RULE-IO-014" }) == false)
    }
    
    @Test("Regola Processi Figli (RULE-PROC-005): intercetta interpreti inattesi e associa ID evento")
    func testUnexpectedChildProcessDetection() {
        let engine = RuleEngineService.shared
        let events = FixtureDatasets.makeUnexpectedChildProcessFixture()
        
        let matches = engine.evaluate(events: events)
        let procMatch = matches.first(where: { $0.ruleId == "RULE-PROC-005" })
        
        #expect(procMatch != nil)
        #expect(procMatch?.severity == .medium)
        #expect(procMatch?.recommendedAction == .requireUserConfirmation)
        #expect(procMatch?.triggeredEventIDs.contains("EVT-PROC-CHILD-01") == true)
        #expect(procMatch?.triggeredEventIDs.contains("EVT-PROC-CHILD-02") == true)
        #expect(procMatch?.matchedIndicator.contains("sh") == true)
    }
    
    @Test("Regola Persistenza Critica (RULE-PERSIST-002): attiva raccomandazione arresto VM")
    func testCriticalPersistenceTriggersStopAction() {
        let engine = RuleEngineService.shared
        let events = FixtureDatasets.makeCriticalPersistenceFixture()
        
        let matches = engine.evaluate(events: events)
        let persistMatch = matches.first(where: { $0.ruleId == "RULE-PERSIST-002" })
        
        #expect(persistMatch != nil)
        #expect(persistMatch?.severity == .critical)
        #expect(persistMatch?.recommendedAction == .stopAuthorizedVM)
        #expect(persistMatch?.triggeredEventIDs.contains("EVT-CRIT-PERSIST") == true)
        
        let classification = engine.classify(matches: matches)
        #expect(classification.classification == .detected)
        #expect(classification.confidence >= 0.95)
    }
    
    @Test("Regola Heartbeat (RULE-HEARTBEAT-000): assenza di telemetria porta a stato degradato (Fail-Closed)")
    func testSensorHeartbeatLossEntersDegradedState() {
        let engine = RuleEngineService.shared
        let events = FixtureDatasets.makeHeartbeatLossFixture()
        
        let matches = engine.evaluate(events: events)
        let heartbeatMatch = matches.first(where: { $0.ruleId == "RULE-HEARTBEAT-000" })
        
        #expect(heartbeatMatch != nil)
        #expect(heartbeatMatch?.severity == .high)
        #expect(heartbeatMatch?.recommendedAction == .markMonitoringDegraded)
        
        let classification = engine.classify(matches: matches)
        #expect(classification.classification == .unverifiable)
    }
    
    @Test("Regola Anti-Tamper (RULE-INJECT-001): prompt injection trattata rigorosamente come dato passivo")
    func testPromptInjectionTreatedAsPureData() {
        let engine = RuleEngineService.shared
        let events = FixtureDatasets.makeHostilePromptInjectionFixture()
        
        let matches = engine.evaluate(events: events)
        let injectMatch = matches.first(where: { $0.ruleId == "RULE-INJECT-001" })
        
        #expect(injectMatch != nil)
        #expect(injectMatch?.recommendedAction == .treatAsDataOnly)
        #expect(injectMatch?.triggeredEventIDs.contains("EVT-INJECT-LOG-02") == true)
        
        // Verifica che l'evento nel dataset mantenga il flag isUntrustedData
        let hostileEvt = events.first(where: { $0.id == "EVT-INJECT-LOG-02" })
        #expect(hostileEvt?.isUntrustedData == true)
    }
}
