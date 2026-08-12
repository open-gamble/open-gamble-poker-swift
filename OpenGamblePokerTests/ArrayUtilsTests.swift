import Testing
@testable import OpenGamblePoker

@Suite("findIndexAdjacent")
struct FindIndexAdjacentTests {
    @Test("Returns the index of the first adjacent pair satisfying the predicate")
    func findsFirstAdjacentPair() {
        #expect(findIndexAdjacent([1, 2, 2, 3]) { $0 == $1 } == 1)
        #expect(findIndexAdjacent([1, 2, 3, 3]) { first, _ in first == 3 } == 2)
    }

    @Test("Returns -1 when the first element never satisfies the predicate")
    func returnsNegativeOneWhenFirstElementNeverMatches() {
        #expect(findIndexAdjacent([1, 2, 3, 4]) { $1 != $0 + 1 } == -1)
    }

    @Test("An empty or single-element array has no adjacent pairs")
    func emptyAndSingleElementArraysReturnNegativeOne() {
        #expect(findIndexAdjacent([Int]()) { $0 == $1 } == -1)
        #expect(findIndexAdjacent([1]) { $0 == $1 } == -1)
    }
}

@Suite("nextOrWrap")
struct NextOrWrapTests {
    @Test("Moves forward skipping empty seats")
    func movesForwardSkippingEmptySeats() {
        let array: [Int?] = [1, nil, 3, 4]
        #expect(nextOrWrap(array, 0) == 2)
        #expect(nextOrWrap(array, 2) == 3)
    }

    @Test("Wraps around at the end of the array")
    func wrapsAroundAtTheEnd() {
        let array: [Int?] = [1, nil, 3, nil]
        #expect(nextOrWrap(array, 3) == 0)
    }
}

@Suite("rotate")
struct RotateTests {
    @Test("Rotates the first count elements to the end")
    func rotatesFirstCountElementsToEnd() {
        var values = [1, 2, 3, 4, 5]
        rotate(&values, 2)
        #expect(values == [3, 4, 5, 1, 2])
    }

    @Test("Rotating by the array length is a no-op")
    func rotatingByArrayLengthIsNoOp() {
        var values = [1, 2, 3]
        rotate(&values, 3)
        #expect(values == [1, 2, 3])
    }

    @Test("A negative count rotates forward by the wrapped remainder")
    func negativeCountRotatesForwardByWrappedRemainder() {
        var values = [1, 2, 3, 4, 5]
        rotate(&values, -1)
        #expect(values == [5, 1, 2, 3, 4])
    }
}

@Suite("unique")
struct UniqueTests {
    @Test("Removes consecutive duplicates by default")
    func removesConsecutiveDuplicates() {
        #expect(unique([1, 1, 2, 2, 2, 3, 1]) == [1, 2, 3, 1])
    }

    @Test("A custom predicate controls what is kept")
    func customPredicateControlsWhatIsKept() {
        let values = [1, 3, 2, 4]
        #expect(unique(values) { $1 > $0 } == [1, 3, 4])
    }

    @Test("An empty array is returned unchanged")
    func emptyArrayIsReturnedUnchanged() {
        #expect(unique([Int]()).isEmpty)
    }
}

@Suite("findMax")
struct FindMaxTests {
    @Test("Returns the element that sorts first under the comparator")
    func returnsElementThatSortsFirst() {
        let values = [3, 1, 2]
        #expect(findMax(values) { $1 - $0 } == 3)
    }

    @Test("Deduplicated equal values resolve to the same element")
    func equalValuesResolveToSameElement() {
        let values = [5, 5, 3]
        #expect(findMax(values) { $1 - $0 } == 5)
    }
}