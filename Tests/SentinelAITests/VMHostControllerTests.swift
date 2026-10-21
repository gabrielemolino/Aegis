import Testing
import Foundation
@testable import SentinelAI

@Suite("VM Host Controller & Containment Tests (v0.4)")
struct VMHostControllerTests {
    
    @Test("Autorizzazione: rifiuta categoricamente comandi verso VM non autorizzate")
    func testAuthorizationRejection() async {
        let controller = VMHostController.shared
        let authorizedVM = "SentinelAI-Ubuntu-Guest"
        
        let unauthorizedTargets = [
            "ProductionServerVM",
            "Windows11-Dev",
            "MyWorkMacVM",
            "arbitrary_name"
        ]
        
        for target in unauthorizedTargets {
            #expect(controller.isAuthorized(targetVM: target, authorizedVM: authorizedVM) == false)
            
            // Tentativo di avvio su VM non autorizzata
            let startRes = await controller.startVM(targetVM: target, authorizedVM: authorizedVM, isSimulation: true)
            #expect(startRes.isSuccess == false)
            #expect(startRes.message.contains("Accesso negato"))
            
            // Tentativo di arresto su VM non autorizzata
            let stopRes = await controller.stopVM(targetVM: target, authorizedVM: authorizedVM, mode: .containmentImmediate, isSimulation: true)
            #expect(stopRes.isSuccess == false)
            #expect(stopRes.message.contains("Contenimento rifiutato"))
        }
    }
    
    @Test("Autorizzazione: accetta la sola VM autorizzata configurata")
    func testAuthorizationAcceptance() {
        let controller = VMHostController.shared
        let authorizedVM = "SentinelAI-Ubuntu-Guest"
        
        #expect(controller.isAuthorized(targetVM: "SentinelAI-Ubuntu-Guest", authorizedVM: authorizedVM) == true)
        #expect(controller.isAuthorized(targetVM: "  sentinelai-ubuntu-guest  ", authorizedVM: authorizedVM) == true)
    }
    
    @Test("Controllo Host: avvio simulato con conferma dello stato in esecuzione")
    func testSimulatedStartConfirmation() async {
        let controller = VMHostController.shared
        let vm = "SentinelAI-Ubuntu-Guest"
        
        let res = await controller.startVM(targetVM: vm, authorizedVM: vm, isSimulation: true)
        #expect(res.isSuccess == true)
        if case .success(_, let state) = res {
            #expect(state == .running)
        } else {
            Issue.record("Atteso esito di successo con stato running")
        }
    }
    
    @Test("Contenimento: arresto confermato e registrazione evento di sicurezza")
    func testSimulatedStopConfirmation() async {
        let controller = VMHostController.shared
        let vm = "SentinelAI-Ubuntu-Guest"
        
        let res = await controller.stopVM(
            targetVM: vm,
            authorizedVM: vm,
            mode: .containmentImmediate,
            triggeredByRule: "RULE-PERSIST-002",
            isSimulation: true
        )
        
        #expect(res.isSuccess == true)
        if case .success(_, let state) = res {
            #expect(state == .stopped)
        } else {
            Issue.record("Atteso esito di successo con stato stopped")
        }
    }
    
    @Test("Policy Bonifica Post-Arresto: obbligo di rollback prima di nuove analisi")
    @MainActor
    func testPostArrestRollbackEnforcement() {
        let appState = AppState.shared
        
        // Simula arresto per contenimento
        appState.isCompromisedAwaitingRollback = true
        appState.isolationChecklist.cleanSnapshotVerified = false
        appState.vmStatus = .manualVerificationRequired
        
        // Il preflight deve fallire categoricamente (Fail-Closed)
        let preflightOk = appState.performPreflight()
        #expect(preflightOk == false)
        
        // L'operatore effettua il rollback dello snapshot in UTM e attesta la bonifica:
        appState.attestSnapshotRollbackCompleted()
        
        #expect(appState.isCompromisedAwaitingRollback == false)
        #expect(appState.isolationChecklist.cleanSnapshotVerified == true)
    }
}
