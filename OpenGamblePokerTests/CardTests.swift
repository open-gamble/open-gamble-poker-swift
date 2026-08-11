import Testing
@testable import OpenGamblePoker

@Suite struct CardRankTests {
    @Test func numericOrderMatchesPokerRank() {
        #expect(CardRank.two.rawValue == 0)
        #expect(CardRank.three.rawValue == 1)
        #expect(CardRank.four.rawValue == 2)
        #expect(CardRank.five.rawValue == 3)
        #expect(CardRank.six.rawValue == 4)
        #expect(CardRank.seven.rawValue == 5)
        #expect(CardRank.eight.rawValue == 6)
        #expect(CardRank.nine.rawValue == 7)
        #expect(CardRank.ten.rawValue == 8)
        #expect(CardRank.jack.rawValue == 9)
        #expect(CardRank.queen.rawValue == 10)
        #expect(CardRank.king.rawValue == 11)
        #expect(CardRank.ace.rawValue == 12)
    }
}

@Suite struct CardSuitTests {
    @Test func numericOrder() {
        #expect(CardSuit.clubs.rawValue == 0)
        #expect(CardSuit.diamonds.rawValue == 1)
        #expect(CardSuit.hearts.rawValue == 2)
        #expect(CardSuit.spades.rawValue == 3)
    }
}

@Suite struct CardCompareTests {
    private func card(_ rank: CardRank, _ suit: CardSuit) -> Card {
        Card(rank: rank, suit: suit)
    }

    @Test func differentSuitsCompareBySuitDescending() {
        #expect(Card.compare(card(.two, .clubs), card(.ace, .spades)) > 0)
        #expect(Card.compare(card(.ace, .spades), card(.two, .clubs)) < 0)
    }

    @Test func sameSuitComparesByRankDescending() {
        #expect(Card.compare(card(.two, .hearts), card(.king, .hearts)) > 0)
        #expect(Card.compare(card(.king, .hearts), card(.two, .hearts)) < 0)
    }

    @Test func equalCardsCompareEqual() {
        #expect(Card.compare(card(.queen, .diamonds), card(.queen, .diamonds)) == 0)
    }
}
