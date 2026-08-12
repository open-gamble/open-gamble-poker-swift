import Testing
@testable import OpenGamblePoker

@Suite("Player construction")
struct PlayerConstructionTests {
    @Test("A new player has an empty stack")
    func newPlayerHasEmptyStack() {
        let player = Player()
        #expect(player.totalChips == 0)
        #expect(player.stack == 0)
        #expect(player.betSize == 0)
    }

    @Test("Initializing with a total seeds the stack")
    func initWithTotalSeedsStack() {
        let player = Player(total: 1000)
        #expect(player.totalChips == 1000)
        #expect(player.stack == 1000)
    }

    @Test("Copies are independent values")
    func copiesAreIndependent() {
        var original = Player(total: 1000)
        original.bet(300)
        var copy = original
        copy.addToStack(100)
        #expect(original.totalChips == 1000)
        #expect(original.betSize == 300)
        #expect(copy.totalChips == 1100)
        #expect(copy.betSize == 300)
    }
}

@Suite("Player stack operations")
struct PlayerStackTests {
    @Test("addToStack credits the total")
    func addToStackCreditsTotal() {
        var player = Player(total: 1000)
        player.addToStack(500)
        #expect(player.totalChips == 1500)
        #expect(player.stack == 1500)
    }

    @Test("takeFromStack debits the total")
    func takeFromStackDebitsTotal() {
        var player = Player(total: 1000)
        player.takeFromStack(200)
        #expect(player.totalChips == 800)
        #expect(player.stack == 800)
    }
}

@Suite("Player betting")
struct PlayerBettingTests {
    @Test("bet commits chips to the current street")
    func betCommitsChipsToStreet() {
        var player = Player(total: 1000)
        player.bet(400)
        #expect(player.betSize == 400)
        #expect(player.stack == 600)
        #expect(player.totalChips == 1000)
    }

    @Test("Re-betting replaces the committed amount")
    func rebettingReplacesCommittedAmount() {
        var player = Player(total: 1000)
        player.bet(300)
        player.bet(500)
        #expect(player.betSize == 500)
        #expect(player.stack == 500)
    }

    @Test("Betting the full total goes all-in")
    func bettingFullTotalGoesAllIn() {
        var player = Player(total: 1000)
        player.bet(1000)
        #expect(player.stack == 0)
        #expect(player.betSize == 1000)
    }

    @Test("takeFromBet moves the full bet out of the stack")
    func takeFromBetMovesFullBet() {
        var player = Player(total: 1000)
        player.bet(400)
        player.takeFromBet(400)
        #expect(player.totalChips == 600)
        #expect(player.betSize == 0)
        #expect(player.stack == 600)
    }

    @Test("takeFromBet can move a partial bet")
    func takeFromBetMovesPartialBet() {
        var player = Player(total: 1000)
        player.bet(500)
        player.takeFromBet(200)
        #expect(player.totalChips == 800)
        #expect(player.betSize == 300)
        #expect(player.stack == 500)
    }
}
