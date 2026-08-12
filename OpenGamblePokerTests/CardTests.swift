import Testing
@testable import OpenGamblePoker

@Suite("CardRank")
struct CardRankTests {
    @Test("Raw values follow poker rank order: two = 0 ... ace = 12")
    func numericOrderMatchesPokerRank() {
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

@Suite("CardSuit")
struct CardSuitTests {
    @Test("Raw values follow the TS enum order: clubs = 0 ... spades = 3")
    func numericOrder() {
        #expect(CardSuit.clubs.rawValue == 0)
        #expect(CardSuit.diamonds.rawValue == 1)
        #expect(CardSuit.hearts.rawValue == 2)
        #expect(CardSuit.spades.rawValue == 3)
    }
}

@Suite("Card compare")
struct CardCompareTests {
    private func card(_ rank: CardRank, _ suit: CardSuit) -> Card {
        Card(rank: rank, suit: suit)
    }

    @Test("Different suits compare by suit descending")
    func differentSuitsCompareBySuitDescending() {
        #expect(Card.compare(card(.two, .clubs), card(.ace, .spades)) > 0)
        #expect(Card.compare(card(.ace, .spades), card(.two, .clubs)) < 0)
    }

    @Test("Same-suit cards compare by rank descending")
    func sameSuitComparesByRankDescending() {
        #expect(Card.compare(card(.two, .hearts), card(.king, .hearts)) > 0)
        #expect(Card.compare(card(.king, .hearts), card(.two, .hearts)) < 0)
    }

    @Test("Two identical cards compare equal")
    func equalCardsCompareEqual() {
        #expect(Card.compare(card(.queen, .diamonds), card(.queen, .diamonds)) == 0)
    }
}
