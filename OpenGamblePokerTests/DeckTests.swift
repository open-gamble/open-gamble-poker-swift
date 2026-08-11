import Testing
@testable import OpenGamblePoker

private func noopShuffle(_ cards: inout [Card]) {}

private func reverseShuffle(_ cards: inout [Card]) {
    cards.reverse()
}

@Suite struct DeckConstructionTests {
    @Test func createsFiftyTwoUniqueCards() {
        let deck = Deck { _ in }
        var unique = Set<Int>()
        for _ in 0..<52 {
            let card = deck.draw()
            unique.insert(card.rank.rawValue * 4 + card.suit.rawValue)
        }
        #expect(unique.count == 52)
    }

    @Test func constructionOrderIsSuitMajorRankMinor() {
        let deck = Deck { _ in }
        #expect(deck.draw() == Card(rank: .ace, suit: .spades))
        #expect(deck.draw() == Card(rank: .king, suit: .spades))
        _ = deck.draw()
        _ = deck.draw()
        #expect(deck.draw() == Card(rank: .ten, suit: .spades))
    }
}

@Suite struct DeckDrawTests {
    @Test func preArrangedCardsDrawInInsertionOrder() {
        let deck = Deck { cards in
            cards[51] = Card(rank: .two, suit: .clubs)
            cards[50] = Card(rank: .king, suit: .hearts)
        }
        #expect(deck.draw() == Card(rank: .two, suit: .clubs))
        #expect(deck.draw() == Card(rank: .king, suit: .hearts))
    }

    @Test func countStaysFiftyTwoAfterDraws() {
        let deck = Deck { _ in }
        _ = deck.draw()
        _ = deck.draw()
        _ = deck.draw()
        #expect(deck.count == 52)
    }
}

@Suite struct DeckReshuffleTests {
    @Test func fillAndShuffleResetsCountAndReshufflesWholeArray() {
        let deck = Deck(shuffleAlgorithm: reverseShuffle)
        _ = deck.draw()
        _ = deck.draw()
        _ = deck.draw()

        deck.fillAndShuffle()

        var drawn = 0
        #expect(deck.draw() == Card(rank: .ace, suit: .spades))
        drawn += 1
        for _ in 0..<51 {
            _ = deck.draw()
            drawn += 1
        }
        #expect(drawn == 52)
        #expect(deck.count == 52)
    }
}
