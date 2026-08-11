import Testing
@testable import OpenGamblePoker

@Suite("ChipRange")
struct ChipRangeTests {
    @Test("contains is inclusive at both bounds")
    func containsIsInclusiveAtBounds() {
        let range = ChipRange(min: 100, max: 500)
        #expect(range.contains(100))
        #expect(range.contains(500))
        #expect(range.contains(300))
        #expect(!range.contains(99))
        #expect(!range.contains(501))
    }

    @Test("A degenerate range contains only its single value")
    func degenerateRangeContainsSingleValue() {
        let range = ChipRange(min: 250, max: 250)
        #expect(range.contains(250))
        #expect(!range.contains(249))
        #expect(!range.contains(251))
    }
}
