public struct Dealer: Sendable {
    public struct Action: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let fold = Action(rawValue: 1 << 0)
        public static let check = Action(rawValue: 1 << 1)
        public static let call = Action(rawValue: 1 << 2)
        public static let bet = Action(rawValue: 1 << 3)
        public static let raise = Action(rawValue: 1 << 4)
    }

    public struct ActionRange: Sendable {
        public var action: Action = .fold
        public var chipRange: ChipRange?

        public init(chipRange: ChipRange? = nil) {
            self.chipRange = chipRange
        }

        public func contains(_ action: Action, bet: Chips = 0) -> Bool {
            precondition(Dealer.isValid(action), "The action representation must be valid")
            if Dealer.isAggressive(action) {
                return chipRange?.contains(bet) ?? false
            }
            return true
        }
    }

    private let _button: SeatIndex
    var _communityCards: CommunityCards
    private var _holeCards: [HoleCards?]
    private var _players: SeatArray
    private var _bettingRound: BettingRound?
    private let _forcedBets: ForcedBets
    private let _deck: Deck
    private var _handInProgress: Bool = false
    private var _roundOfBetting: RoundOfBetting = .preflop
    private var _bettingRoundsCompleted: Bool = false
    private var _potManager = PotManager()
    private var _winners: [[(SeatIndex, Hand, HoleCards)]] = []

    public init(players: SeatArray, button: SeatIndex, forcedBets: ForcedBets, deck: Deck, communityCards: CommunityCards, numSeats: Int = 9) {
        precondition(deck.count == 52, "Deck must be whole")
        precondition(communityCards.cards.isEmpty, "No community cards should have been dealt")
        self._players = players
        self._button = button
        self._forcedBets = forcedBets
        self._deck = deck
        self._communityCards = communityCards
        self._holeCards = Array(repeating: nil, count: numSeats)
    }

    public static func isValid(_ action: Action) -> Bool {
        bitCount(action.rawValue) == 1
    }

    public static func isAggressive(_ action: Action) -> Bool {
        action.contains(.bet) || action.contains(.raise)
    }

    public func handInProgress() -> Bool {
        _handInProgress
    }

    public func bettingRoundsCompleted() -> Bool {
        precondition(handInProgress(), "Hand must be in progress")
        return _bettingRoundsCompleted
    }

    public func playerToAct() -> SeatIndex {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        precondition(_bettingRound != nil)
        return _bettingRound!.playerToAct
    }

    public func players() -> SeatArray {
        _bettingRound?.players() ?? []
    }

    public func bettingRoundPlayers() -> SeatArray {
        _players
    }

    public func roundOfBetting() -> RoundOfBetting {
        precondition(handInProgress(), "Hand must be in progress")
        return _roundOfBetting
    }

    public func numActivePlayers() -> Int {
        _bettingRound?.numActivePlayers ?? 0
    }

    public func biggestBet() -> Chips {
        _bettingRound?.biggestBet ?? 0
    }

    public func bettingRoundInProgress() -> Bool {
        _bettingRound?.inProgress ?? false
    }

    public func isContested() -> Bool {
        _bettingRound?.isContested ?? false
    }

    public func legalActions() -> ActionRange {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        precondition(_bettingRound != nil)
        guard let player = _players[_bettingRound!.playerToAct] else {
            preconditionFailure("Player to act must exist")
        }
        let actions = _bettingRound!.legalActions()
        var actionRange = ActionRange(chipRange: actions.chipRange)

        if _bettingRound!.biggestBet - player.betSize == 0 {
            actionRange.action.insert(.check)
            if actions.canRaise {
                if player.betSize > 0 {
                    actionRange.action.insert(.raise)
                } else {
                    actionRange.action.insert(.bet)
                }
            }
        } else {
            actionRange.action.insert(.call)
            if actions.canRaise {
                actionRange.action.insert(.raise)
            }
        }

        return actionRange
    }

    public func pots() -> [Pot] {
        precondition(handInProgress(), "Hand must be in progress")
        return _potManager.pots
    }

    public func button() -> SeatIndex {
        _button
    }

    public func holeCards() -> [HoleCards?] {
        precondition(handInProgress() || bettingRoundInProgress(), "Hand must be in progress or showdown must have ended")
        return _holeCards
    }

    public mutating func startHand() {
        precondition(!handInProgress(), "Hand must not be in progress")
        _bettingRoundsCompleted = false
        _roundOfBetting = .preflop
        _winners = []
        collectAnte()
        let bigBlindSeat = postBlinds()
        let firstAction = advanceSeat(from: bigBlindSeat)
        dealHoleCards()
        let activeCount = _players.enumerated().filter { seat, player in
            guard let player else { return false }
            return player.stack != 0 || seat == bigBlindSeat
        }.count
        if activeCount > 1 {
            _bettingRound = BettingRound(players: _players, firstToAct: firstAction, minRaise: _forcedBets.blinds.big, biggestBet: _forcedBets.blinds.big)
        }
        _handInProgress = true
    }

    public mutating func actionTaken(_ action: Action, bet: Chips = 0) {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        precondition(legalActions().contains(action, bet: bet), "Action must be legal")
        precondition(_bettingRound != nil)

        if action.contains(.check) || action.contains(.call) {
            _bettingRound?.actionTaken(.match)
        } else if action.contains(.bet) || action.contains(.raise) {
            _bettingRound?.actionTaken(.raise, bet: bet)
        } else {
            precondition(action.contains(.fold))
            let seat = playerToAct()
            guard var foldingPlayer = _players[seat] else {
                preconditionFailure("Folding player must exist")
            }
            _potManager.betFolded(foldingPlayer.betSize)
            foldingPlayer.takeFromBet(foldingPlayer.betSize)
            _players[seat] = nil
            _bettingRound?.actionTaken(.leave)
        }
        syncPlayersFromBettingRound()
    }

    private mutating func syncPlayersFromBettingRound() {
        guard let bettingRound = _bettingRound else { return }
        for index in _players.indices where _players[index] != nil {
            if let player = bettingRound.player(index) {
                _players[index] = player
            }
        }
    }

    public mutating func endBettingRound() {
        precondition(!_bettingRoundsCompleted, "Betting rounds must not be completed")
        precondition(!bettingRoundInProgress(), "Betting round must not be in progress")

        _potManager.collectBetsFrom(&_players)
        if (_bettingRound?.numActivePlayers ?? 0) <= 1 {
            _roundOfBetting = .river
            let singleEligiblePlayer = _potManager.pots.count == 1 && _potManager.pots[0].eligiblePlayers.count == 1
            if !singleEligiblePlayer {
                dealCommunityCards()
            }
            _bettingRoundsCompleted = true
        } else if _roundOfBetting.rawValue < RoundOfBetting.river.rawValue {
            _roundOfBetting = next(_roundOfBetting)
            _players = _bettingRound!.activePlayers.enumerated().map { index, active in
                active ? _players[index] : nil
            }
            _bettingRound = BettingRound(players: _players, firstToAct: advanceSeat(from: _button), minRaise: _forcedBets.blinds.big)
            dealCommunityCards()
            precondition(!_bettingRoundsCompleted)
        } else {
            precondition(_roundOfBetting == .river)
            _bettingRoundsCompleted = true
        }
    }

    public func winners() -> [[(SeatIndex, Hand, HoleCards)]] {
        precondition(!handInProgress(), "Hand must not be in progress")
        return _winners
    }

    public mutating func showdown() {
        precondition(_roundOfBetting == .river, "Round of betting must be river")
        precondition(!bettingRoundInProgress(), "Betting round must not be in progress")
        precondition(bettingRoundsCompleted(), "Betting rounds must be completed")

        _handInProgress = false
        if _potManager.pots.count == 1 && _potManager.pots[0].eligiblePlayers.count == 1 {
            let index = _potManager.pots[0].eligiblePlayers[0]
            guard var player = _players[index] else {
                preconditionFailure("Eligible player must exist")
            }
            player.addToStack(_potManager.pots[0].size)
            _players[index] = player
            return
        }

        for pot in _potManager.pots {
            var playerResults = pot.eligiblePlayers.map { seatIndex -> (SeatIndex, Hand) in
                guard let holeCards = _holeCards[seatIndex] else {
                    preconditionFailure("Eligible player must have hole cards")
                }
                return (seatIndex, Hand.create(holeCards: holeCards, communityCards: _communityCards))
            }

            playerResults.sort { Hand.compare($0.1, $1.1) < 0 }

            let lastWinnerIndex = findIndexAdjacent(playerResults) { Hand.compare($0.1, $1.1) != 0 }
            let numberOfWinners = lastWinnerIndex == -1 ? playerResults.count : lastWinnerIndex + 1
            let oddChips = pot.size % numberOfWinners
            let payout = (pot.size - oddChips) / numberOfWinners
            let winningPlayerResults = Array(playerResults.prefix(numberOfWinners))

            for playerResult in winningPlayerResults {
                _players[playerResult.0]?.addToStack(payout)
            }

            _winners.append(winningPlayerResults.map { playerResult in
                guard let holeCards = _holeCards[playerResult.0] else {
                    preconditionFailure("Winner must have hole cards")
                }
                return (playerResult.0, playerResult.1, holeCards)
            })

            if oddChips != 0 {
                var winners: SeatArray = Array(repeating: nil, count: _players.count)
                for playerResult in winningPlayerResults {
                    winners[playerResult.0] = _players[playerResult.0]
                }

                var seat = _button
                var remaining = oddChips
                while remaining != 0 {
                    seat = nextOrWrap(winners, seat)
                    guard winners[seat] != nil else {
                        preconditionFailure("Winner must exist")
                    }
                    _players[seat]?.addToStack(1)
                    remaining -= 1
                }
            }
        }
    }

    private func advanceSeat(from seat: SeatIndex) -> SeatIndex {
        OpenGamblePoker.nextOrWrap(_players, seat)
    }

    private mutating func collectAnte() {
        guard let ante = _forcedBets.ante else {
            return
        }

        var total = 0
        for index in _players.indices {
            guard var player = _players[index] else { continue }
            let paidAnte = min(ante, player.totalChips)
            player.takeFromStack(paidAnte)
            _players[index] = player
            total += paidAnte
        }

        _potManager.pots[0].add(total)
    }

    private mutating func postBlinds() -> SeatIndex {
        var seat = _button
        let numPlayers = _players.filter { $0 != nil }.count
        if numPlayers != 2 {
            seat = advanceSeat(from: seat)
        }
        guard var smallBlind = _players[seat] else {
            preconditionFailure("Small blind must exist")
        }
        smallBlind.bet(min(_forcedBets.blinds.small, smallBlind.totalChips))
        _players[seat] = smallBlind
        seat = advanceSeat(from: seat)
        guard var bigBlind = _players[seat] else {
            preconditionFailure("Big blind must exist")
        }
        bigBlind.bet(min(_forcedBets.blinds.big, bigBlind.totalChips))
        _players[seat] = bigBlind
        return seat
    }

    private mutating func dealHoleCards() {
        for (index, player) in _players.enumerated() {
            if player != nil {
                _holeCards[index] = (_deck.draw(), _deck.draw())
            }
        }
    }

    private mutating func dealCommunityCards() {
        var cards: [Card] = []
        let numCardsToDeal = _roundOfBetting.rawValue - _communityCards.cards.count
        for _ in 0..<numCardsToDeal {
            cards.append(_deck.draw())
        }
        _communityCards.deal(cards)
    }
}
