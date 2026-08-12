import Testing
@testable import OpenGamblePoker

@Suite("Pot")
struct PotTests {
    @Test("Some bets remaining are collected into the pot")
    func someBetsRemaining() {
        var players: SeatArray = Array(repeating: nil, count: 9)
        players[0] = Player(total: 100)
        players[1] = Player(total: 100)
        players[2] = Player(total: 100)
        players[0]?.bet(0)
        players[1]?.bet(20)

        var pot = Pot()
        pot.collectBetsFrom(&players)

        #expect(pot.size == 20)
        #expect(pot.eligiblePlayers.count == 1)
        #expect(players[1]?.betSize == 0)
    }

    @Test("No bets remaining leaves all seated players eligible")
    func noBetsRemaining() {
        var players: SeatArray = Array(repeating: nil, count: 9)
        players[0] = Player(total: 100)
        players[1] = Player(total: 100)
        players[2] = Player(total: 100)

        var pot = Pot()
        pot.collectBetsFrom(&players)

        #expect(pot.size == 0)
        #expect(pot.eligiblePlayers.count == 3)
    }

    @Test("Players who folded are not kept as eligible after a betting round with no bets")
    func foldedPlayersNotKeptEligible() {
        var players: SeatArray = Array(repeating: nil, count: 9)
        players[0] = Player(total: 100)
        players[1] = Player(total: 100)
        players[0]?.bet(10)
        players[1]?.bet(10)

        var pot = Pot()
        pot.collectBetsFrom(&players)
        players[0] = nil
        pot.collectBetsFrom(&players)

        #expect(pot.eligiblePlayers.count == 1)
    }
}