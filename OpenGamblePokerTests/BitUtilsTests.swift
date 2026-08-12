import Testing
@testable import OpenGamblePoker

@Suite("bitCount")
struct BitCountTests {
    @Test("Counts the set bits of an integer")
    func countsSetBits() {
        #expect(bitCount(0) == 0)
        #expect(bitCount(1) == 1)
        #expect(bitCount(5) == 2)
        #expect(bitCount(255) == 8)
        #expect(bitCount(0xFF) == 8)
    }

    @Test("A single-bit mask has a popcount of one")
    func singleBitMaskHasPopcountOne() {
        #expect(bitCount(1 << 0) == 1)
        #expect(bitCount(1 << 5) == 1)
        #expect(bitCount(1 << 10) == 1)
    }

    @Test("Combined masks have a popcount equal to the number of flags")
    func combinedMasksCountFlags() {
        #expect(bitCount((1 << 0) | (1 << 3)) == 2)
        #expect(bitCount((1 << 1) | (1 << 4) | (1 << 9)) == 3)
    }
}