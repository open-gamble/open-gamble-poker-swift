public final class Deck: @unchecked Sendable {
    public typealias ShuffleAlgorithm = (inout [Card]) -> Void

    private var cards: [Card]
    private var size: Int
    private let shuffleAlgorithm: ShuffleAlgorithm

    public var count: Int { cards.count }

    public init(shuffleAlgorithm: @escaping ShuffleAlgorithm = Deck.defaultShuffle) {
        var cards: [Card] = []
        cards.reserveCapacity(52)
        for suit in CardSuit.clubs.rawValue...CardSuit.spades.rawValue {
            for rank in CardRank.two.rawValue...CardRank.ace.rawValue {
                cards.append(Card(rank: CardRank(rawValue: rank)!, suit: CardSuit(rawValue: suit)!))
            }
        }
        self.cards = cards
        self.size = 52
        self.shuffleAlgorithm = shuffleAlgorithm
        self.shuffleAlgorithm(&self.cards)
    }

    public func fillAndShuffle() {
        size = 52
        shuffleAlgorithm(&cards)
    }

    public func draw() -> Card {
        precondition(size > 0, "Cannot draw from an empty deck")
        size -= 1
        return cards[size]
    }

    public static func defaultShuffle(_ cards: inout [Card]) {
        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            let newIndex = Int.random(in: 0...index)
            cards.swapAt(index, newIndex)
        }
    }
}
