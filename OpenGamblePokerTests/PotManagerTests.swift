import Testing
@testable import OpenGamblePoker

@Suite("Pot Manager")
struct PotManagerTests {
    @Test("Collects bets into main and side pots")
    func collectBets() {
        var players: SeatArray = Array(repeating: nil, count: 9)
        players[0] = Player(total: 100)
        players[1] = Player(total: 100)
        players[2] = Player(total: 100)
        players[0]?.bet(20)
        players[1]?.bet(40)
        players[2]?.bet(60)

        var potManager = PotManager()
        potManager.collectBetsFrom(&players)

        #expect(potManager.pots.count == 3)
        #expect(potManager.pots[0].size == 60)
        #expect(potManager.pots[1].size == 40)
        #expect(potManager.pots[2].size == 20)
    }
}