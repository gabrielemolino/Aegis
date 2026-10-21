import Testing
import Foundation
@testable import SentinelAI

@Suite("UTM Management & Hardening Tests (v0.2)")
struct UTMManagementTests {
    
    @Test("Validazione nome VM: accetta identificatori conformi")
    func testValidVMNames() {
        let service = UTMManagementService.shared
        
        let validNames = [
            "SentinelAI-Ubuntu-Guest",
            "ubuntu-arm64-sandbox",
            "vm_isolated_01",
            "SentinelVM"
        ]
        
        for name in validNames {
            let res = service.validateVMName(name)
            #expect(res.isValid == true)
            #expect(res.errorReason == nil)
            #expect(res.sanitized == name)
        }
    }
    
    @Test("Validazione nome VM: rifiuta injection, caratteri speciali e traversal")
    func testRejectsMaliciousVMNames() {
        let service = UTMManagementService.shared
        
        let invalidNames = [
            "; rm -rf /",
            "VM && echo hacked",
            "$(whoami)",
            "VM`id`",
            "../../etc/passwd",
            "VM con spazi non consentiti",
            ""
        ]
        
        for name in invalidNames {
            let res = service.validateVMName(name)
            #expect(res.isValid == false)
            #expect(res.errorReason != nil)
        }
    }
    
    @Test("Hardening Checklist: richiede tassativamente tutti i 5 criteri di isolamento")
    func testIsolationChecklistEnforcement() {
        let service = UTMManagementService.shared
        
        var config = UTMVMConfig(
            vmName: "TestVM",
            isNetworkIsolated: true,
            isFolderSharingDisabled: true,
            isClipboardSharingDisabled: true,
            isUsbPassthroughDisabled: true,
            hasCleanSnapshot: false // Snapshot mancante
        )
        
        #expect(config.isFullyHardened == false)
        let check1 = service.verifyIsolationChecklist(config: config)
        #expect(check1.isCompliant == false)
        #expect(check1.missingSteps.count == 1)
        #expect(check1.missingSteps.first?.contains("clean-baseline") == true)
        
        // Convalida anche lo snapshot: ora deve risultare conforme (5/5)
        config.hasCleanSnapshot = true
        #expect(config.isFullyHardened == true)
        let check2 = service.verifyIsolationChecklist(config: config)
        #expect(check2.isCompliant == true)
        #expect(check2.missingSteps.isEmpty)
        #expect(config.complianceScore.passed == 5)
        #expect(config.complianceScore.total == 5)
    }
    
    @Test("Policy Bonifica: la sospensione conserva lo stato compromesso e non è bonifica")
    func testSuspensionPolicyStatement() {
        let caveat = UTMBonificaPolicy.suspensionCaveat
        #expect(caveat.contains("sospensione"))
        #expect(caveat.contains("NON costituisce una bonifica"))
        #expect(caveat.contains("clean-baseline"))
    }
    
    @Test("Interrogazione stato VM: timeout di sicurezza non bloccante")
    func testQueryVMStatusTimeoutSafety() async {
        let service = UTMManagementService.shared
        
        let start = Date()
        // Timeout breve (0.3s)
        let res = await service.queryVMStatus(vmName: "SentinelAI-NonExistent-Test-VM", timeout: 0.3)
        let duration = Date().timeIntervalSince(start)
        
        // Deve ritornare rapidamente senza deadlock o blocchi
        #expect(duration < 2.0)
        #expect(!res.rawDetails.isEmpty)
    }
}
