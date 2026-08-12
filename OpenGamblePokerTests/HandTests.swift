import Testing
@testable import OpenGamblePoker

private func makeCards(_ description: String) -> [Card] {
    description.split(whereSeparator: \.isWhitespace).map { part in
        let characters = Array(part.uppercased())
        let rank: CardRank
        switch characters[0] {
        case "2": rank = .two
        case "3": rank = .three
        case "4": rank = .four
        case "5": rank = .five
        case "6": rank = .six
        case "7": rank = .seven
        case "8": rank = .eight
        case "9": rank = .nine
        case "T": rank = .ten
        case "J": rank = .jack
        case "Q": rank = .queen
        case "K": rank = .king
        case "A": rank = .ace
        default: preconditionFailure("Invalid rank: \(characters[0])")
        }
        let suit: CardSuit
        switch characters[1] {
        case "S": suit = .spades
        case "H": suit = .hearts
        case "C": suit = .clubs
        case "D": suit = .diamonds
        default: preconditionFailure("Invalid suit: \(characters[1])")
        }
        return Card(rank: rank, suit: suit)
    }
}

@Suite("Get suited cards")
struct GetSuitedCardsTests {
    @Test("Suited cards")
    func suitedCards() {
        let allCards = [
            makeCards("Ac Ac Ac Ac Kc 2c 2c"),
            makeCards("2c Ac Ac Kc Kc 2c Ac"),
            makeCards("As Ac As Ks Kc Ks 2s"),
            makeCards("Ac Ac Ac Kc Ks Ks 2s"),
        ]
        let suited = [
            makeCards("Ac Ac Ac Ac Kc 2c 2c"),
            makeCards("Ac Ac Ac Kc Kc 2c 2c"),
            makeCards("As As Ks Ks 2s"),
            nil,
        ]
        for index in allCards.indices {
            #expect(Hand.getSuitedCards(allCards[index]) == suited[index])
        }
    }
}

@Suite("Get straight cards")
struct GetStraightCardsTests {
    @Test("Straight cards")
    func straightCards() {
        let allCards = [
            makeCards("Ac Kc Qc Jc Tc 9c 8c"),
            makeCards("Ac Kc Tc 9c 8c 7c 6c"),
            makeCards("Ac Kc Qc 5c 4c 3s 2c"),
            makeCards("Ac Kc Qc Jc 9c 8c 7c"),
        ]
        let straight = [
            makeCards("Ac Kc Qc Jc Tc"),
            makeCards("Tc 9c 8c 7c 6c"),
            makeCards("5c 4c 3s 2c Ac"),
            nil,
        ]
        for index in allCards.indices {
            #expect(Hand.getStraightCards(allCards[index]) == straight[index])
        }
    }
}

@Suite("High/low hand evaluation")
struct HighLowHandEvaluationTests {
    @Test("Hand rankings")
    func handRankings() {
        let allCards = [
            makeCards("Ac Ac Ac Ac Kc 2c 2c"),
            makeCards("Ac Ac Ac Kc Kc 2c 2c"),
            makeCards("Ac Ac Ac Kc Kc Kc 2c"),
            makeCards("Ac Ac Kc Kc 3c 2c 2c"),
            makeCards("Ac Ac Kc Qc Jc Tc 2c"),
            makeCards("Ac Kc Qc Jc 9c 8c 7c"),
        ]
        let handRankings: [HandRanking] = [
            .fourOfAKind,
            .fullHouse,
            .threeOfAKind,
            .twoPair,
            .pair,
            .highCard,
        ]
        for index in allCards.indices {
            #expect(Hand.highLowHandEval(allCards[index]).ranking == handRankings[index])
        }
    }
}

@Suite("Straight/flush hand evaluation")
struct StraightFlushHandEvaluationTests {
    @Test("Hand rankings")
    func handRankings() {
        let allCards = [
            makeCards("Ac Qc Tc 9c 7h 2c 3h"),
            makeCards("Ts 9c 8d 7c 6h 4c 5h"),
            makeCards("As 2c 3d 4c 5h Kc Qh"),
            makeCards("Ks Qs Ts Js 9s 8s 7s"),
            makeCards("As Ks Qs Js Ts 8s 7s"),
        ]
        let handRankings: [HandRanking] = [
            .flush,
            .straight,
            .straight,
            .straightFlush,
            .royalFlush,
        ]
        for index in allCards.indices {
            #expect(Hand.straightFlushEval(allCards[index])?.ranking == handRankings[index])
        }
    }
}

@Suite("Hand from seven cards")
struct HandFromSevenCardsTests {
    @Test("Hands")
    func hands() {
        let allCards = [
            makeCards("Ac Qc Tc 9c 7h 2c 3h"),
            makeCards("Ts 9c 8d 7c 6h 4c 5h"),
            makeCards("As 2c 3d 4c 5h Kc Qh"),
            makeCards("Ks Qs Ts Js 9s 8s 7s"),
            makeCards("As Ks Qs Js Ts 8s 7s"),

            makeCards("Ac Ac Ac Ac Kc 2c 2c"),
            makeCards("Ac Ac Ac Kc Kc 2c 2c"),
            makeCards("Ac Ac Ac Kc Kc Kc 2c"),
            makeCards("Ac Ac Kc Kc 3c 2c 2c"),
            makeCards("Ac Ah Kc Qh Jc 9h 2c"),
            makeCards("Ah Kc Qs Jd 9c 8c 7c"),

            makeCards("3s 3d 6c Qc Ad 6s Ac"),
        ]
        let handCards = [
            makeCards("Ac Qc Tc 9c 2c"),
            makeCards("Ts 9c 8d 7c 6h"),
            makeCards("5h 4c 3d 2c As"),
            makeCards("Ks Qs Js Ts 9s"),
            makeCards("As Ks Qs Js Ts"),

            makeCards("Ac Ac Ac Ac Kc"),
            makeCards("Ac Ac Ac Kc Kc"),
            makeCards("Ac Ac Ac Kc Kc"),
            makeCards("Ac Ac Kc Kc 3c"),
            makeCards("Ac Ah Kc Qh Jc"),
            makeCards("Ah Kc Qs Jd 9c"),

            makeCards("Ad Ac 6c 6s Qc"),
        ]
        for index in allCards.indices {
            #expect(Hand.of(allCards[index]).cards == handCards[index])
        }
    }
}