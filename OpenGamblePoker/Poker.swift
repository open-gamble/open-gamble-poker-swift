public enum Poker {
    public struct ForcedBets: Sendable, Equatable {
        public let ante: Int
        public let bigBlind: Int
        public let smallBlind: Int

        public init(smallBlind: Int, bigBlind: Int, ante: Int = 0) {
            self.ante = ante
            self.bigBlind = bigBlind
            self.smallBlind = smallBlind
        }
    }

    public struct Card: Sendable, Equatable {
        public enum Rank: String, Sendable {
            case two = "2"
            case three = "3"
            case four = "4"
            case five = "5"
            case six = "6"
            case seven = "7"
            case eight = "8"
            case nine = "9"
            case ten = "T"
            case jack = "J"
            case queen = "Q"
            case king = "K"
            case ace = "A"
        }

        public enum Suit: String, Sendable {
            case clubs
            case diamonds
            case hearts
            case spades
        }

        public let rank: Rank
        public let suit: Suit

        public init(rank: Rank, suit: Suit) {
            self.rank = rank
            self.suit = suit
        }
    }

    public enum Action: String, Sendable {
        case fold
        case check
        case call
        case bet
        case raise
    }

    public enum AutomaticAction: String, Sendable {
        case fold
        case checkFold = "check/fold"
        case check
        case call
        case callAny = "call any"
        case allIn = "all-in"
    }

    public struct Seat: Sendable, Equatable {
        public let totalChips: Chips
        public let stack: Chips
        public let betSize: Chips

        public init(totalChips: Chips, stack: Chips, betSize: Chips) {
            self.totalChips = totalChips
            self.stack = stack
            self.betSize = betSize
        }
    }

    public struct LegalActions: Sendable, Equatable {
        public let actions: [Action]
        public let chipRange: ChipRange?

        public init(actions: [Action], chipRange: ChipRange?) {
            self.actions = actions
            self.chipRange = chipRange
        }
    }

    public struct HandInfo: Sendable, Equatable {
        public let cards: [Card]
        public let ranking: HandRanking
        public let strength: Int

        public init(cards: [Card], ranking: HandRanking, strength: Int) {
            self.cards = cards
            self.ranking = ranking
            self.strength = strength
        }
    }

    public struct Winner: Sendable, Equatable {
        public let seatIndex: SeatIndex
        public let hand: HandInfo
        public let holeCards: [Card]

        public init(seatIndex: SeatIndex, hand: HandInfo, holeCards: [Card]) {
            self.seatIndex = seatIndex
            self.hand = hand
            self.holeCards = holeCards
        }
    }

    public final class Table {
        private var _table: OpenGamblePoker.Table

        public init(forcedBets: ForcedBets, numSeats: Int? = nil) {
            _table = OpenGamblePoker.Table(
                forcedBets: (
                    ante: forcedBets.ante == 0 ? nil : forcedBets.ante,
                    blinds: (small: forcedBets.smallBlind, big: forcedBets.bigBlind)
                ),
                numSeats: numSeats ?? 9
            )
        }

        public func playerToAct() -> SeatIndex {
            _table.playerToAct()
        }

        public func button() -> SeatIndex {
            _table.button()
        }

        public func seats() -> [Seat?] {
            _table.seats().map { player in
                player.map { player in
                    Seat(totalChips: player.totalChips, stack: player.stack, betSize: player.betSize)
                }
            }
        }

        public func handPlayers() -> [Seat?] {
            _table.handPlayers().map { player in
                player.map { player in
                    Seat(totalChips: player.totalChips, stack: player.stack, betSize: player.betSize)
                }
            }
        }

        public func numActivePlayers() -> Int {
            _table.numActivePlayers()
        }

        public func pots() -> [Pot] {
            _table.pots()
        }

        public func forcedBets() -> ForcedBets {
            let forcedBets = _table.forcedBets()
            return ForcedBets(
                smallBlind: forcedBets.blinds.small,
                bigBlind: forcedBets.blinds.big,
                ante: forcedBets.ante ?? 0
            )
        }

        public func setForcedBets(_ forcedBets: ForcedBets) {
            _table.setForcedBets(
                (
                    ante: forcedBets.ante == 0 ? nil : forcedBets.ante,
                    blinds: (small: forcedBets.smallBlind, big: forcedBets.bigBlind)
                )
            )
        }

        public func numSeats() -> Int {
            _table.numSeats()
        }

        public func startHand(seat: SeatIndex? = nil) {
            _table.startHand(seat: seat)
        }

        public func isHandInProgress() -> Bool {
            _table.handInProgress()
        }

        public func isBettingRoundInProgress() -> Bool {
            _table.bettingRoundInProgress()
        }

        public func areBettingRoundsCompleted() -> Bool {
            _table.bettingRoundsCompleted()
        }

        public func roundOfBetting() -> RoundOfBetting {
            _table.roundOfBetting()
        }

        public func communityCards() -> [Card] {
            _table.communityCards().cards.map(Poker.cardMapper)
        }

        public func legalActions() -> LegalActions {
            let legalActions = _table.legalActions()
            return LegalActions(
                actions: actionFlagToStringArray(legalActions.action),
                chipRange: legalActions.chipRange
            )
        }

        public func holeCards() -> [[Card]?] {
            _table.holeCards().map { holeCards in
                holeCards.map { holeCards in
                    [Poker.cardMapper(holeCards.0), Poker.cardMapper(holeCards.1)]
                }
            }
        }

        public func actionTaken(_ action: Action, betSize: Chips = 0) {
            _table.actionTaken(actionFlag(action), bet: betSize)
        }

        public func endBettingRound() {
            _table.endBettingRound()
        }

        public func showdown() {
            _table.showdown()
        }

        public func winners() -> [[Winner]] {
            _table.winners().map { potWinners in
                potWinners.map { seatIndex, hand, holeCards in
                    Winner(
                        seatIndex: seatIndex,
                        hand: HandInfo(
                            cards: hand.cards.map(Poker.cardMapper),
                            ranking: hand.ranking,
                            strength: hand.strength
                        ),
                        holeCards: [Poker.cardMapper(holeCards.0), Poker.cardMapper(holeCards.1)]
                    )
                }
            }
        }

        public func automaticActions() -> [AutomaticAction?] {
            _table.automaticActions().map { action in
                guard let action else { return nil }
                return automaticActionFlagToStringArray(action).first
            }
        }

        public func canSetAutomaticActions(_ seatIndex: SeatIndex) -> Bool {
            _table.canSetAutomaticAction(seatIndex)
        }

        public func legalAutomaticActions(_ seatIndex: SeatIndex) -> [AutomaticAction] {
            automaticActionFlagToStringArray(_table.legalAutomaticActions(seatIndex))
        }

        public func setAutomaticAction(_ seatIndex: SeatIndex, _ action: AutomaticAction?) {
            _table.setAutomaticAction(seatIndex, action.flatMap(automaticActionFlag))
        }

        public func sitDown(_ seatIndex: SeatIndex, _ buyIn: Chips) {
            _table.sitDown(seatIndex, buyIn)
        }

        public func standUp(_ seatIndex: SeatIndex) {
            _table.standUp(seatIndex)
        }
    }

    private static func cardMapper(_ card: OpenGamblePoker.Card) -> Card {
        Card(rank: rankMapper(card.rank), suit: suitMapper(card.suit))
    }

    private static func rankMapper(_ rank: CardRank) -> Card.Rank {
        switch rank {
        case .two: return .two
        case .three: return .three
        case .four: return .four
        case .five: return .five
        case .six: return .six
        case .seven: return .seven
        case .eight: return .eight
        case .nine: return .nine
        case .ten: return .ten
        case .jack: return .jack
        case .queen: return .queen
        case .king: return .king
        case .ace: return .ace
        }
    }

    private static func suitMapper(_ suit: CardSuit) -> Card.Suit {
        switch suit {
        case .clubs: return .clubs
        case .diamonds: return .diamonds
        case .hearts: return .hearts
        case .spades: return .spades
        }
    }

    private static func actionFlagToStringArray(_ action: Dealer.Action) -> [Action] {
        var actions: [Action] = []
        if action.contains(.fold) { actions.append(.fold) }
        if action.contains(.check) { actions.append(.check) }
        if action.contains(.call) { actions.append(.call) }
        if action.contains(.bet) { actions.append(.bet) }
        if action.contains(.raise) { actions.append(.raise) }
        return actions
    }

    private static func automaticActionFlagToStringArray(_ automaticAction: OpenGamblePoker.Table.AutomaticAction) -> [AutomaticAction] {
        var automaticActions: [AutomaticAction] = []
        if automaticAction.contains(.fold) { automaticActions.append(.fold) }
        if automaticAction.contains(.checkFold) { automaticActions.append(.checkFold) }
        if automaticAction.contains(.check) { automaticActions.append(.check) }
        if automaticAction.contains(.call) { automaticActions.append(.call) }
        if automaticAction.contains(.callAny) { automaticActions.append(.callAny) }
        if automaticAction.contains(.allIn) { automaticActions.append(.allIn) }
        return automaticActions
    }

    private static func automaticActionFlag(_ automaticAction: AutomaticAction) -> OpenGamblePoker.Table.AutomaticAction {
        switch automaticAction {
        case .fold: return .fold
        case .checkFold: return .checkFold
        case .check: return .check
        case .call: return .call
        case .callAny: return .callAny
        case .allIn: return .allIn
        }
    }

    private static func actionFlag(_ action: Action) -> Dealer.Action {
        switch action {
        case .fold: return .fold
        case .check: return .check
        case .call: return .call
        case .bet: return .bet
        case .raise: return .raise
        }
    }
}
