public struct PotManager: Sendable {
    public private(set) var pots: [Pot]
    private var aggregateFoldedBets: Chips = 0

    public init() {
        pots = [Pot()]
    }

    public mutating func betFolded(_ amount: Chips) {
        aggregateFoldedBets += amount
    }

    public mutating func collectBetsFrom(_ players: inout SeatArray) {
        while true {
            let minBet = pots[pots.count - 1].collectBetsFrom(&players)

            let numberOfEligiblePlayers = pots[pots.count - 1].eligiblePlayers.count
            let aggregateFoldedBetsConsumedAmount = min(aggregateFoldedBets, numberOfEligiblePlayers * minBet)
            pots[pots.count - 1].add(aggregateFoldedBetsConsumedAmount)
            aggregateFoldedBets -= aggregateFoldedBetsConsumedAmount

            let anyPlayerStillBetting = players.contains { candidate in
                if let candidate {
                    return candidate.betSize != 0
                }
                return false
            }

            if anyPlayerStillBetting {
                pots.append(Pot())
                continue
            } else if aggregateFoldedBets != 0 {
                pots[pots.count - 1].add(aggregateFoldedBets)
                aggregateFoldedBets = 0
            }
            break
        }
    }
}
