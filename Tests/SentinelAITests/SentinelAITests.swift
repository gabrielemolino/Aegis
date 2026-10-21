import Testing
@testable import SentinelAI

@Suite("SentinelAI Baseline Tests")
struct SentinelAITests {
    @Test("Verifica sanity check baseline")
    func testSanity() {
        #expect(true)
    }
}
