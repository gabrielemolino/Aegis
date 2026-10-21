import Testing
import Foundation
@testable import SentinelAI

@Suite("Report & Classification Tests")
struct ReportAndClassificationTests {
    
    @Test("Verifica completezza delle 4 classificazioni ammesse")
    func testClassificationTypes() {
        let expected = ["Rilevato", "Sospetto", "Non rilevato", "Non verificabile"]
        let actual = [
            AnalysisClassification.detected.rawValue,
            AnalysisClassification.suspicious.rawValue,
            AnalysisClassification.notDetected.rawValue,
            AnalysisClassification.unverifiable.rawValue
        ]
        
        #expect(actual == expected)
    }
    
    @Test("Verifica report simulato conforme alle specifiche e con disclaimer espliciti")
    @MainActor
    func testSimulatedReportStructure() {
        let file = SafeTargetFile(
            name: "sample.pkg",
            path: "/tmp/sample.pkg",
            sizeBytes: 1048576,
            sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
        
        let report = AnalysisReport(
            targetFile: file,
            classification: .suspicious,
            confidenceScore: 0.75,
            summary: "Rilevata attività anomala simulata",
            evidence: ["Modifiche multiple in /tmp"],
            rulesTriggered: [
                RuleTrigger(
                    id: "R-01",
                    ruleName: "TempBurst",
                    severity: .medium,
                    description: "Burst in cartella temp",
                    matchedIndicator: "count > 10"
                )
            ],
            actionsExecuted: [
                ContainmentAction(
                    actionType: "Alert generato",
                    targetVM: "SentinelAI-Ubuntu-Guest",
                    status: "Eseguito",
                    isSimulation: true
                )
            ],
            limitations: ["Analisi limitata all'intervallo temporale v0.1"],
            isSimulatedDemo: true
        )
        
        #expect(report.isSimulatedDemo == true)
        #expect(report.confidenceScore >= 0.0 && report.confidenceScore <= 1.0)
        #expect(!report.limitations.isEmpty)
        #expect(report.actionsExecuted.first?.isSimulation == true)
    }
    
    @Test("Verifica checklist di isolamento e conteggio controlli pendenti")
    func testIsolationChecklistPendingCount() {
        var checklist = IsolationChecklist()
        // Di default cleanSnapshotVerified è false
        #expect(checklist.cleanSnapshotVerified == false)
        #expect(checklist.allRequirementsMet == false)
        #expect(checklist.pendingChecksCount == 1)
        
        // Quando lo snapshot è attestato:
        checklist.cleanSnapshotVerified = true
        #expect(checklist.allRequirementsMet == true)
        #expect(checklist.pendingChecksCount == 0)
    }
}
