import Testing
@testable import OpenGamblePoker

@Suite("Betting round")
struct BettingRoundTests {
    private func newBettingRound() -> BettingRound {
        var players: SeatArray = Array(repeating: nil, count: 9)
        players[0] = Player(total: 1)
        players[1] = Player(total: 1)
        players[2] = Player(total: 1)
        return BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)
    }

    @Suite("Testing valid actions")
    struct ValidActionsTests {
        @Suite("A betting round")
        struct OneBettingRoundTests {
            @Test("Precondition")
            func precondition() {
                let round = makeRound()
                #expect(round.playerToAct == 0)
                #expect(round.biggestBet == 50)
                #expect(round.minRaise == 50)
            }

            @Test("The player has less chips than the biggest bet: he cannot raise")
            func lessChipsThanBiggestBetCannotRaise() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 25)
                players[1] = Player(total: 1)
                players[2] = Player(total: 1)
                let round = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

                #expect(players[0]!.totalChips < round.biggestBet)
                #expect(!round.legalActions().canRaise)
            }

            @Test("The player has chips equal to the biggest bet: he cannot raise")
            func equalChipsToBiggestBetCannotRaise() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 50)
                players[1] = Player(total: 1)
                players[2] = Player(total: 1)
                let round = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

                #expect(players[0]!.totalChips == round.biggestBet)
                #expect(!round.legalActions().canRaise)
            }

            @Test("The player has more chips than the biggest bet but less than the minimum re-raise: all-in only")
            func shortStackRaiseIsAllInOnly() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 75)
                players[1] = Player(total: 1)
                players[2] = Player(total: 1)
                let round = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

                #expect(players[0]!.totalChips > round.biggestBet)
                #expect(players[0]!.totalChips < round.biggestBet + round.minRaise)

                let action = round.legalActions()
                #expect(action.canRaise)
                #expect(action.chipRange.min == players[0]!.totalChips)
                #expect(action.chipRange.max == players[0]!.totalChips)
            }

            @Test("The player has chips equal to the minimum re-raise: all-in only")
            func exactMinRaiseIsAllInOnly() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 1)
                players[2] = Player(total: 1)
                let round = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

                #expect(players[0]!.totalChips == round.biggestBet + round.minRaise)

                let action = round.legalActions()
                #expect(action.canRaise)
                #expect(action.chipRange.min == players[0]!.totalChips)
                #expect(action.chipRange.max == players[0]!.totalChips)
            }

            @Test("The player has more chips than the minimum re-raise: any amount from min re-raise to stack")
            func deepStackRaiseRange() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 150)
                players[1] = Player(total: 1)
                players[2] = Player(total: 1)
                let round = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

                #expect(players[0]!.totalChips > round.biggestBet + round.minRaise)

                let action = round.legalActions()
                #expect(action.canRaise)
                #expect(action.chipRange.min == round.biggestBet + round.minRaise)
                #expect(action.chipRange.max == players[0]!.totalChips)
            }

            private func makeRound() -> BettingRound {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 1)
                players[1] = Player(total: 1)
                players[2] = Player(total: 1)
                return BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)
            }
        }
    }

    @Suite("Betting round actions map to round actions properly")
    struct ActionMappingTests {
        private func makeBettingRound() -> BettingRound {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 1000)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            return BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)
        }

        @Test("Precondition")
        func precondition() {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 1000)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            let round = Round(activePlayers: players.map { $0 != nil }, firstToAct: 0)
            let bettingRound = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

            #expect(round == bettingRound.round)
            #expect(bettingRound.playerToAct == 0)
        }

        @Test("A player raises for less than his entire stack")
        func raiseForLessThanStack() {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 1000)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            var round = Round(activePlayers: players.map { $0 != nil }, firstToAct: 0)
            var bettingRound = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

            bettingRound.actionTaken(.raise, bet: 200)
            #expect(bettingRound._players[0]!.stack > 0)
            round.actionTaken(.aggressive)
            #expect(round == bettingRound.round)
        }

        @Test("A player raises his entire stack")
        func raiseEntireStack() {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 1000)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            var round = Round(activePlayers: players.map { $0 != nil }, firstToAct: 0)
            var bettingRound = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

            bettingRound.actionTaken(.raise, bet: 1000)
            #expect(bettingRound._players[0]!.stack == 0)
            round.actionTaken([.aggressive, .leave])
            #expect(round == bettingRound.round)
        }

        @Test("A player matches for less than his entire stack")
        func matchForLessThanStack() {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 1000)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            var round = Round(activePlayers: players.map { $0 != nil }, firstToAct: 0)
            var bettingRound = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

            bettingRound.actionTaken(.match)
            #expect(bettingRound._players[0]!.stack > 0)
            round.actionTaken(.passive)
            #expect(round == bettingRound.round)
        }

        @Test("A player matches for his entire stack")
        func matchEntireStack() {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 50)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            var round = Round(activePlayers: players.map { $0 != nil }, firstToAct: 0)
            var bettingRound = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

            bettingRound.actionTaken(.match)
            #expect(bettingRound._players[0]!.stack == 0)
            round.actionTaken([.passive, .leave])
            #expect(round == bettingRound.round)
        }

        @Test("A player leaves")
        func leave() {
            var players: SeatArray = Array(repeating: nil, count: 9)
            players[0] = Player(total: 1000)
            players[1] = Player(total: 1000)
            players[2] = Player(total: 1000)
            var round = Round(activePlayers: players.map { $0 != nil }, firstToAct: 0)
            var bettingRound = BettingRound(players: players, firstToAct: 0, minRaise: 50, biggestBet: 50)

            bettingRound.actionTaken(.leave)
            round.actionTaken(.leave)
            #expect(round == bettingRound.round)
        }
    }
}
