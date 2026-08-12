public enum RoundOfBetting: Int, Sendable {
    case preflop = 0
    case flop = 3
    case turn = 4
    case river = 5
}

public func next(_ roundOfBetting: RoundOfBetting) -> RoundOfBetting {
    if roundOfBetting == .preflop {
        return .flop
    }
    precondition(roundOfBetting != .river, "Cannot advance past the river")
    return RoundOfBetting(rawValue: roundOfBetting.rawValue + 1)!
}

public struct CommunityCards: Sendable {
    public private(set) var cards: [Card] = []

    public init() {}

    public mutating func deal(_ cards: [Card]) {
        precondition(cards.count <= 5 - self.cards.count, "Cannot deal more than there is undealt cards")
        self.cards += cards
    }
}
