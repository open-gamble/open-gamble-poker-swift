public struct BettingRound: Sendable {
    public enum Action: Sendable {
        case leave
        case match
        case raise
    }

    public struct ActionRange: Sendable {
        public let canRaise: Bool
        public let chipRange: ChipRange

        public init(canRaise: Bool, chipRange: ChipRange = ChipRange(min: 0, max: 0)) {
            self.canRaise = canRaise
            self.chipRange = chipRange
        }
    }

    private(set) var _players: SeatArray
    public private(set) var round: Round
    private(set) var biggestBet: Chips
    private(set) var minRaise: Chips

    public init(players: SeatArray, firstToAct: SeatIndex, minRaise: Chips, biggestBet: Chips = 0) {
        precondition(firstToAct < players.count, "Seat index must be in the valid range")
        precondition(players[firstToAct] != nil, "First player to act must exist")
        self.round = Round(activePlayers: players.map { $0 != nil }, firstToAct: firstToAct)
        self._players = players
        self.biggestBet = biggestBet
        self.minRaise = minRaise
    }

    public var inProgress: Bool {
        round.inProgress
    }

    public var isContested: Bool {
        round.isContested
    }

    public var playerToAct: SeatIndex {
        round.playerToAct
    }

    public var numActivePlayers: Int {
        round.numActivePlayers
    }

    public var activePlayers: [Bool] {
        round.activePlayers
    }

    public func players() -> SeatArray {
        round.activePlayers.indices.map { index in
            round.activePlayers[index] ? _players[index] : nil
        }
    }

    public func player(_ seat: SeatIndex) -> Player? {
        guard seat >= 0 && seat < _players.count else { return nil }
        return _players[seat]
    }

    public func legalActions() -> ActionRange {
        guard let player = _players[round.playerToAct] else {
            preconditionFailure("Player to act must exist")
        }
        let playerChips = player.totalChips
        let canRaise = playerChips > biggestBet
        if canRaise {
            let minBet = biggestBet + minRaise
            let raiseRange = ChipRange(min: min(minBet, playerChips), max: playerChips)
            return ActionRange(canRaise: canRaise, chipRange: raiseRange)
        } else {
            return ActionRange(canRaise: canRaise)
        }
    }

    public mutating func actionTaken(_ action: Action, bet: Chips = 0) {
        guard var player = _players[round.playerToAct] else {
            preconditionFailure("Player to act must exist")
        }
        switch action {
        case .raise:
            precondition(isRaiseValid(bet: bet), "Raise amount is not valid")
            player.bet(bet)
            _players[round.playerToAct] = player
            minRaise = bet - biggestBet
            biggestBet = bet
            var actionFlag: Round.Action = .aggressive
            if player.stack == 0 {
                actionFlag.insert(.leave)
            }
            round.actionTaken(actionFlag)
        case .match:
            player.bet(min(biggestBet, player.totalChips))
            _players[round.playerToAct] = player
            var actionFlag: Round.Action = .passive
            if player.stack == 0 {
                actionFlag.insert(.leave)
            }
            round.actionTaken(actionFlag)
        case .leave:
            round.actionTaken(.leave)
        }
    }

    private func isRaiseValid(bet: Chips) -> Bool {
        guard let player = _players[round.playerToAct] else {
            preconditionFailure("Player to act must exist")
        }
        let playerChips = player.stack + player.betSize
        let minBet = biggestBet + minRaise
        if playerChips > biggestBet && playerChips < minBet {
            return bet == playerChips
        }
        return bet >= minBet && bet <= playerChips
    }
}