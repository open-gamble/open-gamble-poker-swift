import Testing
@testable import OpenGamblePoker

@Suite("Community cards")
struct CommunityCardsTests {
    private func aceOfSpades() -> Card {
        Card(rank: .ace, suit: .spades)
    }

    @Test("A new community cards object has no cards dealt")
    func precondition() {
        let communityCards = CommunityCards()
        #expect(communityCards.cards.isEmpty)
    }

    @Test("A flop deal leaves three cards")
    func flopDeal() {
        var communityCards = CommunityCards()
        communityCards.deal([aceOfSpades(), aceOfSpades(), aceOfSpades()])
        #expect(communityCards.cards.count == 3)
    }

    @Test("A turn deal leaves four cards")
    func turnDeal() {
        var communityCards = CommunityCards()
        communityCards.deal([aceOfSpades(), aceOfSpades(), aceOfSpades(), aceOfSpades()])
        #expect(communityCards.cards.count == 4)
    }

    @Test("A river deal leaves all five cards")
    func riverDeal() {
        var communityCards = CommunityCards()
        communityCards.deal([aceOfSpades(), aceOfSpades(), aceOfSpades(), aceOfSpades(), aceOfSpades()])
        #expect(communityCards.cards.count == 5)
    }

    @Test("A turn deal after a flop leaves four cards")
    func turnAfterFlop() {
        var communityCards = CommunityCards()
        communityCards.deal([aceOfSpades(), aceOfSpades(), aceOfSpades()])
        communityCards.deal([aceOfSpades()])
        #expect(communityCards.cards.count == 4)
    }

    @Test("A river deal after a flop leaves five cards")
    func riverAfterFlop() {
        var communityCards = CommunityCards()
        communityCards.deal([aceOfSpades(), aceOfSpades(), aceOfSpades()])
        communityCards.deal([aceOfSpades(), aceOfSpades()])
        #expect(communityCards.cards.count == 5)
    }

    @Test("A river deal after a turn leaves five cards")
    func riverAfterTurn() {
        var communityCards = CommunityCards()
        communityCards.deal([aceOfSpades(), aceOfSpades(), aceOfSpades(), aceOfSpades()])
        communityCards.deal([aceOfSpades()])
        #expect(communityCards.cards.count == 5)
    }
}

@Suite("Round of betting")
struct RoundOfBettingTests {
    @Test("Raw values encode the number of community cards dealt")
    func numericValues() {
        #expect(RoundOfBetting.preflop.rawValue == 0)
        #expect(RoundOfBetting.flop.rawValue == 3)
        #expect(RoundOfBetting.turn.rawValue == 4)
        #expect(RoundOfBetting.river.rawValue == 5)
    }

    @Test("next advances preflop to flop and increments afterwards")
    func nextAdvances() {
        #expect(next(.preflop) == .flop)
        #expect(next(.flop) == .turn)
        #expect(next(.turn) == .river)
    }
}
