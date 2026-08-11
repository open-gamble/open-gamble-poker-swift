public struct ChipRange: Sendable, Equatable {
    public let min: Int
    public let max: Int

    public init(min: Int, max: Int) {
        self.min = min
        self.max = max
    }

    public func contains(_ amount: Int) -> Bool {
        min <= amount && amount <= max
    }
}
