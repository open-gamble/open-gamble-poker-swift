public struct Round: Sendable, Equatable {
    public struct Action: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let leave = Action(rawValue: 1 << 0)
        public static let passive = Action(rawValue: 1 << 1)
        public static let aggressive = Action(rawValue: 1 << 2)
    }

    public private(set) var activePlayers: [Bool]
    public private(set) var playerToAct: SeatIndex
    public private(set) var lastAggressiveActor: SeatIndex
    private var contested: Bool = false
    private var firstAction: Bool = true
    public private(set) var numActivePlayers: Int = 0

    public init(activePlayers: [Bool], firstToAct: SeatIndex) {
        precondition(firstToAct < activePlayers.count)
        self.activePlayers = activePlayers
        self.playerToAct = firstToAct
        self.lastAggressiveActor = firstToAct
        self.numActivePlayers = activePlayers.filter { $0 }.count
    }

    public var inProgress: Bool {
        (contested || numActivePlayers > 1) && (firstAction || playerToAct != lastAggressiveActor)
    }

    public var isContested: Bool {
        contested
    }

    public mutating func actionTaken(_ action: Action) {
        precondition(inProgress)
        precondition(!(action.contains(.passive) && action.contains(.aggressive)))

        if firstAction {
            firstAction = false
        }

        if action.contains(.aggressive) {
            lastAggressiveActor = playerToAct
            contested = true
        } else if action.contains(.passive) {
            contested = true
        }

        if action.contains(.leave) {
            activePlayers[playerToAct] = false
            numActivePlayers -= 1
        }

        incrementPlayer()
    }

    private mutating func incrementPlayer() {
        repeat {
            playerToAct += 1
            if playerToAct == activePlayers.count {
                playerToAct = 0
            }
            if playerToAct == lastAggressiveActor {
                break
            }
        } while !activePlayers[playerToAct]
    }
}
