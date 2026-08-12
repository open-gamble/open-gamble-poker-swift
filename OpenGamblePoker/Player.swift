public struct Player: Sendable, Equatable {
    private var total: Int
    private(set) var betSize: Int

    public init(total: Int = 0, betSize: Int = 0) {
        self.total = total
        self.betSize = betSize
    }

    public var stack: Int { total - betSize }
    public var totalChips: Int { total }

    public mutating func addToStack(_ amount: Int) {
        total += amount
    }

    public mutating func takeFromStack(_ amount: Int) {
        total -= amount
    }

    public mutating func bet(_ amount: Int) {
        precondition(amount <= total, "Player cannot bet more than he/she has")
        precondition(amount >= betSize, "Player must bet more than he/she has previously")
        betSize = amount
    }

    public mutating func takeFromBet(_ amount: Int) {
        precondition(amount <= betSize, "Cannot take from bet more than is there")
        total -= amount
        betSize -= amount
    }
}
