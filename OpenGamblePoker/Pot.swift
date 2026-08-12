public struct Pot: Sendable {
    public private(set) var eligiblePlayers: [SeatIndex] = []
    public private(set) var size: Chips = 0

    public init() {}

    public mutating func add(_ amount: Chips) {
        precondition(amount >= 0, "Cannot add a negative amount to the pot")
        size += amount
    }

    public mutating func collectBetsFrom(_ players: inout SeatArray) -> Chips {
        let firstBetterIndex = players.firstIndex { player in
            guard let player else { return false }
            return player.betSize != 0
        }

        if let firstBetterIndex {
            let minBet = players[(firstBetterIndex + 1)...].reduce(players[firstBetterIndex]!.betSize) { acc, player in
                guard let player, player.betSize != 0, player.betSize < acc else { return acc }
                return player.betSize
            }

            eligiblePlayers = []
            for index in players.indices {
                guard let player = players[index], player.betSize != 0 else { continue }
                players[index]?.takeFromBet(minBet)
                size += minBet
                eligiblePlayers.append(index)
            }

            return minBet
        } else {
            eligiblePlayers = players.indices.filter { players[$0] != nil }
            return 0
        }
    }
}
