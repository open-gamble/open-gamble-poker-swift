public struct Table: Sendable {
    public struct AutomaticAction: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let fold = AutomaticAction(rawValue: 1 << 0)
        public static let checkFold = AutomaticAction(rawValue: 1 << 1)
        public static let check = AutomaticAction(rawValue: 1 << 2)
        public static let call = AutomaticAction(rawValue: 1 << 3)
        public static let callAny = AutomaticAction(rawValue: 1 << 4)
        public static let allIn = AutomaticAction(rawValue: 1 << 5)
    }

    private let _numSeats: Int
    private var _tablePlayers: SeatArray
    private let _deck: Deck
    private var _automaticActions: [AutomaticAction?]
    private var _firstTimeButton = true
    private var _buttonSetManually = false
    private var _button: SeatIndex = 0
    private var _forcedBets: ForcedBets
    private var _dealer: Dealer?
    private var _staged: [Bool]

    public init(forcedBets: ForcedBets, numSeats: Int = 9) {
        precondition(numSeats <= 23, "Maximum 23 players")

        _numSeats = numSeats
        _forcedBets = forcedBets
        _tablePlayers = Array(repeating: nil, count: numSeats)
        _staged = Array(repeating: false, count: numSeats)
        _automaticActions = Array(repeating: nil, count: numSeats)
        _deck = Deck()
    }

    public func playerToAct() -> SeatIndex {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        precondition(_dealer != nil)
        return _dealer!.playerToAct()
    }

    public func button() -> SeatIndex {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.button()
    }

    public func seats() -> SeatArray {
        _tablePlayers
    }

    public func handPlayers() -> SeatArray {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.players()
    }

    public func numActivePlayers() -> Int {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.numActivePlayers()
    }

    public func pots() -> [Pot] {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.pots()
    }

    public func forcedBets() -> ForcedBets {
        _forcedBets
    }

    public mutating func setForcedBets(_ forcedBets: ForcedBets) {
        precondition(!handInProgress(), "Hand must not be in progress")
        _forcedBets = forcedBets
    }

    public func numSeats() -> Int {
        _numSeats
    }

    public mutating func startHand(seat: SeatIndex? = nil) {
        precondition(!handInProgress(), "Hand must not be in progress")
        precondition(
            _tablePlayers.filter { $0 != nil }.count >= 2,
            "There must be at least 2 players at the table"
        )

        if let seat {
            _button = seat
            _buttonSetManually = true
        }

        _staged = Array(repeating: false, count: _numSeats)
        _automaticActions = Array(repeating: nil, count: _numSeats)
        incrementButton()
        _deck.fillAndShuffle()
        var dealer = Dealer(
            players: _tablePlayers,
            button: _button,
            forcedBets: _forcedBets,
            deck: _deck,
            communityCards: CommunityCards(),
            numSeats: _numSeats
        )
        dealer.startHand()
        _dealer = dealer
        updateTablePlayers()
    }

    public func handInProgress() -> Bool {
        _dealer?.handInProgress() ?? false
    }

    public func bettingRoundInProgress() -> Bool {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.bettingRoundInProgress()
    }

    public func bettingRoundsCompleted() -> Bool {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.bettingRoundsCompleted()
    }

    public func roundOfBetting() -> RoundOfBetting {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!.roundOfBetting()
    }

    public func communityCards() -> CommunityCards {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _dealer!._communityCards
    }

    public func legalActions() -> Dealer.ActionRange {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        precondition(_dealer != nil)
        return _dealer!.legalActions()
    }

    public func holeCards() -> [HoleCards?] {
        precondition(
            handInProgress() || bettingRoundsCompleted(),
            "Hand must be in progress or showdown must have ended"
        )
        precondition(_dealer != nil)
        return _dealer!.holeCards()
    }

    public mutating func actionTaken(_ action: Dealer.Action, bet: Chips = 0) {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        precondition(_dealer != nil)

        _dealer!.actionTaken(action, bet: bet)
        while _dealer!.bettingRoundInProgress() {
            amendAutomaticActions()

            let playerToAct = playerToAct()
            if let automaticAction = _automaticActions[playerToAct] {
                takeAutomaticAction(automaticAction)
                _automaticActions[playerToAct] = nil
            } else {
                break
            }
        }

        if bettingRoundInProgress() && singleActivePlayerRemaining() {
            actPassively()
        }

        updateTablePlayers()
    }

    public mutating func endBettingRound() {
        precondition(!bettingRoundInProgress(), "Betting round must not be in progress")
        precondition(!bettingRoundsCompleted(), "Betting rounds must not be completed")
        precondition(_dealer != nil)

        _dealer!.endBettingRound()
        amendAutomaticActions()
        updateTablePlayers()
        clearFoldedBets()
    }

    public mutating func showdown() {
        precondition(!bettingRoundInProgress(), "Betting round must not be in progress")
        precondition(bettingRoundsCompleted(), "Betting rounds must be completed")
        precondition(_dealer != nil)

        _dealer!.showdown()
        updateTablePlayers()
        standUpBustedPlayers()
    }

    public func winners() -> [[(SeatIndex, Hand, HoleCards)]] {
        precondition(!handInProgress(), "Hand must not be in progress")
        return _dealer?.winners() ?? []
    }

    public func automaticActions() -> [AutomaticAction?] {
        precondition(handInProgress(), "Hand must be in progress")
        precondition(_dealer != nil)
        return _automaticActions
    }

    public func canSetAutomaticAction(_ seat: SeatIndex) -> Bool {
        precondition(bettingRoundInProgress(), "Betting round must be in progress")
        return !_staged[seat] && _tablePlayers[seat] != nil
    }

    public func legalAutomaticActions(_ seat: SeatIndex) -> AutomaticAction {
        precondition(canSetAutomaticAction(seat), "Player must be allowed to set automatic actions")
        precondition(_dealer != nil)
        let biggestBet = _dealer!.biggestBet()
        guard let player = _tablePlayers[seat] else {
            preconditionFailure("Player must be seated")
        }
        let betSize = player.betSize
        let totalChips = player.totalChips
        var legalActions: AutomaticAction = [.fold, .allIn]
        let canCheck = biggestBet - betSize == 0
        if canCheck {
            legalActions.insert([.checkFold, .check])
        } else {
            legalActions.insert(.call)
        }
        if biggestBet < totalChips {
            legalActions.insert(.callAny)
        }
        return legalActions
    }

    public mutating func setAutomaticAction(_ seat: SeatIndex, _ action: AutomaticAction?) {
        precondition(canSetAutomaticAction(seat), "Player must be allowed to set automatic actions")
        precondition(seat != playerToAct(), "Player must not be the player to act")
        precondition(
            action == nil || bitCount(action!.rawValue) == 1,
            "Player must pick one automatic action or null"
        )
        precondition(
            action == nil || !action!.intersection(legalAutomaticActions(seat)).isEmpty,
            "Given automatic action must be legal"
        )

        _automaticActions[seat] = action
    }

    public mutating func sitDown(_ seat: SeatIndex, _ buyIn: Chips) {
        precondition(seat < _numSeats && seat >= 0, "Given seat index must be valid")
        precondition(_tablePlayers[seat] == nil, "Given seat must not be occupied")

        _tablePlayers[seat] = Player(total: buyIn)
        _staged[seat] = true
    }

    public mutating func standUp(_ seat: SeatIndex) {
        precondition(seat < _numSeats && seat >= 0, "Given seat index must be valid")
        precondition(_tablePlayers[seat] != nil, "Given seat must be occupied")

        if handInProgress() {
            precondition(bettingRoundInProgress())
            if seat == playerToAct() {
                actionTaken(.fold)
                _tablePlayers[seat] = nil
                _staged[seat] = true
            } else if _dealer!.bettingRoundPlayers()[seat] != nil {
                setAutomaticAction(seat, .fold)
                _tablePlayers[seat] = nil
                _staged[seat] = true

                if singleActivePlayerRemaining() {
                    actPassively()
                }
            }
        } else {
            _tablePlayers[seat] = nil
        }
    }

    private mutating func takeAutomaticAction(_ automaticAction: AutomaticAction) {
        precondition(_dealer != nil)
        let seat = _dealer!.playerToAct()
        guard let player = _dealer!.bettingRoundPlayers()[seat] else {
            preconditionFailure("Player to act must exist")
        }
        let biggestBet = _dealer!.biggestBet()
        let betGap = biggestBet - player.betSize
        let totalChips = player.totalChips

        switch automaticAction {
        case .fold:
            _dealer!.actionTaken(.fold)
        case .checkFold:
            _dealer!.actionTaken(betGap == 0 ? .check : .fold)
        case .check:
            _dealer!.actionTaken(.check)
        case .call:
            _dealer!.actionTaken(.call)
        case .callAny:
            _dealer!.actionTaken(betGap == 0 ? .check : .call)
        case .allIn:
            if totalChips < biggestBet {
                _dealer!.actionTaken(.call)
            } else {
                _dealer!.actionTaken(.raise, bet: totalChips)
            }
        default:
            preconditionFailure("Automatic action must be known")
        }
    }

    private mutating func amendAutomaticActions() {
        precondition(_dealer != nil)

        let biggestBet = _dealer!.biggestBet()
        for seat in 0..<_numSeats {
            guard let automaticAction = _automaticActions[seat] else {
                continue
            }
            guard let player = _dealer!.bettingRoundPlayers()[seat] else {
                preconditionFailure("Automatic action requires a hand player")
            }
            let betGap = biggestBet - player.betSize
            let totalChips = player.totalChips
            if automaticAction.contains(.checkFold), betGap > 0 {
                _automaticActions[seat] = .fold
            } else if automaticAction.contains(.check), betGap > 0 {
                _automaticActions[seat] = nil
            } else if automaticAction.contains(.callAny), biggestBet >= totalChips {
                _automaticActions[seat] = .call
            }
        }
    }

    private mutating func actPassively() {
        precondition(_dealer != nil)
        let legalActions = _dealer!.legalActions()
        if legalActions.action.contains(.bet) {
            actionTaken(.check)
        } else {
            precondition(legalActions.action.contains(.call))
            actionTaken(.call)
        }
    }

    private mutating func incrementButton() {
        if _buttonSetManually {
            _buttonSetManually = false
            _firstTimeButton = false
            if !(_button < _tablePlayers.count && _tablePlayers[_button] != nil) {
                _button = _tablePlayers.firstIndex(where: { $0 != nil }) ?? -1
            }
            precondition(_button != -1)
        } else if _firstTimeButton {
            let seat = _tablePlayers.firstIndex(where: { $0 != nil }) ?? -1
            precondition(seat != -1)
            _button = seat
            _firstTimeButton = false
        } else {
            let offset = _button + 1
            let slice = Array(_tablePlayers[offset...])
            let seat = slice.firstIndex(where: { $0 != nil })
            _button = seat != nil
                ? seat! + offset
                : (_tablePlayers.firstIndex(where: { $0 != nil }) ?? -1)
        }
    }

    private mutating func clearFoldedBets() {
        for seat in 0..<_numSeats {
            let handPlayer = _dealer!.bettingRoundPlayers()[seat]
            let tablePlayer = _tablePlayers[seat]
            if !_staged[seat], handPlayer == nil, tablePlayer != nil, tablePlayer!.betSize > 0 {
                _tablePlayers[seat] = Player(total: tablePlayer!.stack)
            }
        }
    }

    private mutating func updateTablePlayers() {
        precondition(_dealer != nil)
        for seat in 0..<_numSeats {
            if !_staged[seat], let handPlayer = _dealer!.bettingRoundPlayers()[seat] {
                precondition(_tablePlayers[seat] != nil)
                _tablePlayers[seat] = handPlayer
            }
        }
    }

    private func singleActivePlayerRemaining() -> Bool {
        precondition(bettingRoundInProgress())
        precondition(_dealer != nil)

        let bettingRoundPlayers = _dealer!.bettingRoundPlayers()
        let activePlayers = bettingRoundPlayers.enumerated().filter { index, player in
            player != nil && !_staged[index]
        }
        return activePlayers.count == 1
    }

    private mutating func standUpBustedPlayers() {
        precondition(!handInProgress())
        for seat in 0..<_numSeats {
            let player = _tablePlayers[seat]
            if player != nil, player!.totalChips == 0 {
                _tablePlayers[seat] = nil
            }
        }
    }
}
