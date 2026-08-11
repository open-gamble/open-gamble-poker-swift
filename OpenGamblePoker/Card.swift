public enum CardRank: Int, Sendable {
    case two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
}

public enum CardSuit: Int, Sendable {
    case clubs, diamonds, hearts, spades
}

public struct Card: Sendable {
    public let rank: CardRank
    public let suit: CardSuit

    public init(rank: CardRank, suit: CardSuit) {
        self.rank = rank
        self.suit = suit
    }

    public static func compare(_ first: Card, _ second: Card) -> Int {
        let suitDifference = second.suit.rawValue - first.suit.rawValue
        if suitDifference != 0 {
            return suitDifference
        }
        return second.rank.rawValue - first.rank.rawValue
    }
}
