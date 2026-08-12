public enum HandRanking: Int, Sendable {
    case highCard = 0
    case pair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush
    case royalFlush
}

public struct RankInfo: Sendable {
    public let rank: CardRank
    public let count: Int
}

public struct Hand: Sendable {
    public let ranking: HandRanking
    public let strength: Int
    public let cards: [Card]

    public init(ranking: HandRanking, strength: Int, cards: [Card]) {
        precondition(cards.count == 5)
        self.ranking = ranking
        self.strength = strength
        self.cards = cards
    }

    public static func create(holeCards: HoleCards, communityCards: CommunityCards) -> Hand {
        precondition(communityCards.cards.count == 5, "All community cards must be dealt")
        let cards = [holeCards.0, holeCards.1] + communityCards.cards
        return of(cards)
    }

    public static func of(_ cards: [Card]) -> Hand {
        precondition(cards.count == 7)
        let hand1 = highLowHandEval(cards)
        if let hand2 = straightFlushEval(cards) {
            return findMax([hand1, hand2], Hand.compare)
        }
        return hand1
    }

    public static func compare(_ h1: Hand, _ h2: Hand) -> Int {
        let rankingDiff = h2.ranking.rawValue - h1.ranking.rawValue
        if rankingDiff != 0 {
            return rankingDiff
        }
        return h2.strength - h1.strength
    }

    public static func nextRank(_ cards: [Card]) -> RankInfo {
        precondition(!cards.isEmpty)
        let firstRank = cards[0].rank
        let secondRankIndex = cards.firstIndex { $0.rank != firstRank }
        return RankInfo(rank: firstRank, count: secondRankIndex ?? cards.count)
    }

    public static func getStrength(_ cards: [Card]) -> Int {
        precondition(cards.count == 5)
        var sum = 0
        var multiplier = 28561
        var cards = cards
        while true {
            let info = nextRank(cards)
            sum += multiplier * info.rank.rawValue
            cards = Array(cards.dropFirst(info.count))
            if cards.isEmpty {
                break
            }
            multiplier /= 13
        }
        return sum
    }

    public static func getSuitedCards(_ cards: [Card]) -> [Card]? {
        precondition(cards.count == 7)
        var cards = cards.sorted { Card.compare($0, $1) < 0 }
        var first = 0
        while true {
            var last = -1
            for index in (first + 1)..<cards.count where cards[index].suit != cards[first].suit {
                last = index
                break
            }
            if last == -1 {
                last = cards.count
            }
            if last - first >= 5 {
                return Array(cards[first..<last])
            } else if last == cards.count {
                return nil
            }
            first = last
        }
    }

    public static func getStraightCards(_ cards: [Card]) -> [Card]? {
        precondition(cards.count >= 5)
        var cards = cards
        var first = 0
        while true {
            var last = findIndexAdjacent(Array(cards[first...])) { first, second in
                first.rank.rawValue != second.rank.rawValue + 1
            }
            if last == -1 {
                last = cards.count
            } else {
                last += first + 1
            }
            if last - first >= 5 {
                return Array(cards[first..<first + 5])
            } else if last - first == 4 {
                if cards[first].rank == .five && cards[0].rank == .ace {
                    rotate(&cards, first)
                    return Array(cards.prefix(5))
                }
            } else if cards.count - last < 4 {
                return nil
            }
            first = last
        }
    }

    public static func highLowHandEval(_ cards: [Card]) -> Hand {
        precondition(cards.count == 7)
        var cards = cards
        var rankOccurrences = [Int](repeating: 0, count: 13)
        for card in cards {
            rankOccurrences[card.rank.rawValue] += 1
        }
        cards.sort { c1, c2 in
            if rankOccurrences[c1.rank.rawValue] == rankOccurrences[c2.rank.rawValue] {
                return c1.rank.rawValue > c2.rank.rawValue
            }
            return rankOccurrences[c1.rank.rawValue] > rankOccurrences[c2.rank.rawValue]
        }
        let ranking: HandRanking
        let count = nextRank(cards).count
        if count == 4 {
            let kickers = Array(cards.dropFirst(5)).sorted { $0.rank.rawValue > $1.rank.rawValue }
            cards = Array(cards[0..<4]) + kickers
            ranking = .fourOfAKind
        } else if count == 3 {
            let tmp = nextRank(Array(cards.suffix(4)))
            ranking = tmp.count == 2 ? .fullHouse : .threeOfAKind
        } else if count == 2 {
            let tmp = nextRank(Array(cards.suffix(5)))
            if tmp.count == 2 {
                ranking = .twoPair
                let firstPair = Array(cards[0..<count])
                let secondPair = Array(cards[count..<count + tmp.count])
                let kicker = Array(cards[(count + tmp.count)...]).sorted { $0.rank.rawValue > $1.rank.rawValue }[0]
                cards = firstPair + secondPair + [kicker]
            } else {
                ranking = .pair
            }
        } else {
            ranking = .highCard
        }
        let handCards = Array(cards.prefix(5))
        let strength = getStrength(handCards)
        return Hand(ranking: ranking, strength: strength, cards: handCards)
    }

    public static func straightFlushEval(_ cards: [Card]) -> Hand? {
        precondition(cards.count == 7)
        if let suitedCards = getSuitedCards(cards) {
            if let straightCards = getStraightCards(suitedCards) {
                if straightCards[0].rank == .ace {
                    return Hand(ranking: .royalFlush, strength: 0, cards: Array(straightCards.prefix(5)))
                }
                return Hand(ranking: .straightFlush, strength: straightCards[0].rank.rawValue, cards: Array(straightCards.prefix(5)))
            }
            let handCards = Array(suitedCards.prefix(5))
            return Hand(ranking: .flush, strength: getStrength(handCards), cards: handCards)
        }
        var cards = cards.sorted { $0.rank.rawValue > $1.rank.rawValue }
        cards = unique(cards) { $0.rank != $1.rank }
        guard cards.count >= 5 else {
            return nil
        }
        if let straightCards = getStraightCards(cards) {
            return Hand(ranking: .straight, strength: straightCards[0].rank.rawValue, cards: straightCards)
        }
        return nil
    }
}