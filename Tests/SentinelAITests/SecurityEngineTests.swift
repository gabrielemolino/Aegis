import Testing
import Foundation
import CryptoKit
@testable import SentinelAI

@Suite("SecurityEngine Tests")
struct SecurityEngineTests {
    
    @Test("Verifica calcolo crittografico sicuro SHA-256 senza esecuzione")
    @MainActor
    func testSafeFileInspection() throws {
        let engine = SecurityEngine.shared
        
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("sentinel_test_\(UUID().uuidString).txt")
        let testPayload = "SentinelAI Safe Inspection Test Payload"
        try testPayload.write(to: testFileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFileURL) }
        
        let inspected = try engine.inspectFileSafely(at: testFileURL)
        
        #expect(inspected.name == testFileURL.lastPathComponent)
        #expect(inspected.sizeBytes == Int64(testPayload.utf8.count))
        
        // Verifica che l'hash corrisponda a quello di CryptoKit
        let expectedHash = SHA256.hash(data: Data(testPayload.utf8)).map { String(format: "%02hhx", $0) }.joined()
        #expect(inspected.sha256 == expectedHash)
    }
    
    @Test("Verifica Fail-Closed: preflight fallisce se nessun file è selezionato")
    @MainActor
    func testPreflightFailsWithoutFile() {
        let engine = SecurityEngine.shared
        let prereqs = VMPrerequisites(isAppleSilicon: true, isMacOSCompatible: true, isUTMInstalled: true, isVMConfigured: true)
        let isolation = IsolationChecklist(cleanSnapshotVerified: true)
        
        let result = engine.evaluatePreflight(
            targetFile: nil,
            prerequisites: prereqs,
            isolation: isolation,
            vmStatus: .verified
        )
        
        switch result {
        case .passed:
            Issue.record("Preflight non deve passare senza un file selezionato.")
        case .failed(let reasons):
            #expect(reasons.contains(where: { $0.contains("Nessun file selezionato") }))
        }
    }
    
    @Test("Verifica Fail-Closed: preflight fallisce se la VM non è in stato verificata")
    @MainActor
    func testPreflightFailsWhenVMNotVerified() {
        let engine = SecurityEngine.shared
        let file = SafeTargetFile(name: "test.bin", path: "/tmp/test.bin", sizeBytes: 1024, sha256: "abc")
        let prereqs = VMPrerequisites(isAppleSilicon: true, isMacOSCompatible: true, isUTMInstalled: true)
        let isolation = IsolationChecklist(cleanSnapshotVerified: true)
        
        let result = engine.evaluatePreflight(
            targetFile: file,
            prerequisites: prereqs,
            isolation: isolation,
            vmStatus: .notConfigured
        )
        
        switch result {
        case .passed:
            Issue.record("Preflight non deve passare con VM non verificata.")
        case .failed(let reasons):
            #expect(reasons.contains(where: { $0.contains("Verificata") }))
        }
    }
    
    @Test("Verifica Fail-Closed: preflight fallisce se lo snapshot pulito non è confermato")
    @MainActor
    func testPreflightFailsWhenSnapshotUnconfirmed() {
        let engine = SecurityEngine.shared
        let file = SafeTargetFile(name: "test.bin", path: "/tmp/test.bin", sizeBytes: 1024, sha256: "abc")
        let prereqs = VMPrerequisites(isAppleSilicon: true, isMacOSCompatible: true, isUTMInstalled: true, isVMConfigured: true)
        // cleanSnapshotVerified = false
        let isolation = IsolationChecklist(cleanSnapshotVerified: false)
        
        let result = engine.evaluatePreflight(
            targetFile: file,
            prerequisites: prereqs,
            isolation: isolation,
            vmStatus: .verified
        )
        
        switch result {
        case .passed:
            Issue.record("Preflight non deve passare se lo snapshot non è verificato.")
        case .failed(let reasons):
            #expect(reasons.contains(where: { $0.contains("snapshot") }))
        }
    }
    
    @Test("Verifica superamento Preflight quando tutte le condizioni rigorose sono soddisfatte")
    @MainActor
    func testPreflightPassesWhenAllStrictConditionsMet() {
        let engine = SecurityEngine.shared
        let file = SafeTargetFile(name: "safe.pkg", path: "/tmp/safe.pkg", sizeBytes: 2048, sha256: "def456")
        let prereqs = VMPrerequisites(isAppleSilicon: true, isMacOSCompatible: true, isUTMInstalled: true, isVMConfigured: true)
        let isolation = IsolationChecklist(
            hostFolderSharingDisabled: true,
            sharedClipboardDisabled: true,
            vmNetworkDisconnected: true,
            cleanSnapshotVerified: true,
            noUsbPassthrough: true
        )
        
        let result = engine.evaluatePreflight(
            targetFile: file,
            prerequisites: prereqs,
            isolation: isolation,
            vmStatus: .verified
        )
        
        #expect(result == .passed)
    }
}
