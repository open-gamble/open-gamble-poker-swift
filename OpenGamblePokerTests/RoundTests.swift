import Testing
@testable import OpenGamblePoker

@Suite("Round")
struct RoundTests {
    @Test("A contesting action keeps the round in progress")
    func contestingActionKeepsRoundInProgress() {
        var round = Round(activePlayers: [true, true, true], firstToAct: 0)
        round.actionTaken(.aggressive)
        #expect(round.inProgress)
    }

    @Test("Round construction")
    func roundConstruction() {
        let round = Round(activePlayers: [true, true, true], firstToAct: 0)

        #expect(round.inProgress)
        #expect(round.playerToAct == round.lastAggressiveActor)
        #expect(round.playerToAct == 0)
        #expect(round.numActivePlayers == 3)
    }
}

@Suite("Round with two players")
struct TwoPlayerRoundTests {
    private func newRound() -> Round {
        Round(activePlayers: [true, true, false, false, false, false, false, false], firstToAct: 0)
    }

    @Suite("There was no action in the round yet")
    struct NoActionYetTests {
        private func newRound() -> Round {
            Round(activePlayers: [true, true, false, false, false, false, false, false], firstToAct: 0)
        }

        @Test("Precondition")
        func precondition() {
            let round = newRound()
            #expect(round.playerToAct == 0)
            #expect(round.lastAggressiveActor == 0)
            #expect(round.inProgress)
            #expect(round.numActivePlayers == 2)
        }

        @Test("The first player acts aggressively: last aggressive actor remains unchanged")
        func firstAggressiveKeepsLastAggressiveActor() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.lastAggressiveActor == 0)
        }

        @Test("The first player acts aggressively: second player becomes player to act")
        func firstAggressiveAdvancesToSecondPlayer() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.playerToAct == 1)
        }

        @Test("The first player acts aggressively: round is not over")
        func firstAggressiveKeepsRoundInProgress() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.inProgress)
        }

        @Test("The first player acts aggressively: two active players remain")
        func firstAggressiveKeepsTwoActivePlayers() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.numActivePlayers == 2)
        }

        @Test("The first player acts aggressively and leaves: last aggressive actor remains unchanged")
        func firstAggressiveLeaveKeepsLastAggressiveActor() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.lastAggressiveActor == 0)
        }

        @Test("The first player acts aggressively and leaves: second player becomes player to act")
        func firstAggressiveLeaveAdvancesToSecondPlayer() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.playerToAct == 1)
        }

        @Test("The first player acts aggressively and leaves: round is not over")
        func firstAggressiveLeaveKeepsRoundInProgress() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.inProgress)
        }

        @Test("The first player acts aggressively and leaves: one active player remains")
        func firstAggressiveLeaveLeavesOneActivePlayer() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.numActivePlayers == 1)
        }

        @Test("The first player acts passively: last aggressive actor remains unchanged")
        func firstPassiveKeepsLastAggressiveActor() {
            var round = newRound()
            round.actionTaken(.passive)
            #expect(round.lastAggressiveActor == 0)
        }

        @Test("The first player acts passively: second player becomes player to act")
        func firstPassiveAdvancesToSecondPlayer() {
            var round = newRound()
            round.actionTaken(.passive)
            #expect(round.playerToAct == 1)
        }

        @Test("The first player acts passively: round is not over")
        func firstPassiveKeepsRoundInProgress() {
            var round = newRound()
            round.actionTaken(.passive)
            #expect(round.inProgress)
        }

        @Test("The first player acts passively: two active players remain")
        func firstPassiveKeepsTwoActivePlayers() {
            var round = newRound()
            round.actionTaken(.passive)
            #expect(round.numActivePlayers == 2)
        }

        @Test("The first player acts passively and leaves: round is not over")
        func firstPassiveLeaveKeepsRoundInProgress() {
            var round = newRound()
            round.actionTaken([.passive, .leave])
            #expect(round.inProgress)
        }

        @Test("The first player leaves: round is over")
        func firstLeaveEndsRound() {
            var round = newRound()
            round.actionTaken(.leave)
            #expect(!round.inProgress)
        }
    }

    @Suite("The next player is the last aggressive actor")
    struct NextPlayerIsLastAggressiveActorTests {
        private func newRound() -> Round {
            var round = Round(activePlayers: [true, true, false, false, false, false, false, false], firstToAct: 0)
            round.actionTaken(.aggressive)
            return round
        }

        @Test("Precondition")
        func precondition() {
            let round = newRound()
            #expect(round.playerToAct == 1)
            #expect(round.lastAggressiveActor == 0)
            #expect(round.inProgress)
            #expect(round.numActivePlayers == 2)
        }

        @Test("The player to act acts aggressively: becomes the last aggressive actor")
        func aggressiveBecomesLastAggressiveActor() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.lastAggressiveActor == 1)
        }

        @Test("The player to act acts aggressively: last aggressive actor becomes the player to act")
        func aggressiveRotatesToLastAggressiveActor() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.playerToAct == 0)
        }

        @Test("The player to act acts aggressively: round is not over")
        func aggressiveKeepsRoundInProgress() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.inProgress)
        }

        @Test("The player to act acts aggressively: two active players remain")
        func aggressiveKeepsTwoActivePlayers() {
            var round = newRound()
            round.actionTaken(.aggressive)
            #expect(round.numActivePlayers == 2)
        }

        @Test("The player to act acts aggressively and leaves: becomes the last aggressive actor")
        func aggressiveLeaveBecomesLastAggressiveActor() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.lastAggressiveActor == 1)
        }

        @Test("The player to act acts aggressively and leaves: last aggressive actor becomes the player to act")
        func aggressiveLeaveRotatesToLastAggressiveActor() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.playerToAct == 0)
        }

        @Test("The player to act acts aggressively and leaves: round is not over")
        func aggressiveLeaveKeepsRoundInProgress() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.inProgress)
        }

        @Test("The player to act acts aggressively and leaves: one active player remains")
        func aggressiveLeaveLeavesOneActivePlayer() {
            var round = newRound()
            round.actionTaken([.aggressive, .leave])
            #expect(round.numActivePlayers == 1)
        }

        @Test("The player to act acts passively: round is over")
        func passiveEndsRound() {
            var round = newRound()
            round.actionTaken(.passive)
            #expect(!round.inProgress)
        }

        @Test("The player to act acts passively and leaves: round is over")
        func passiveLeaveEndsRound() {
            var round = newRound()
            round.actionTaken([.passive, .leave])
            #expect(!round.inProgress)
        }

        @Test("The player to act leaves: round is over")
        func leaveEndsRound() {
            var round = newRound()
            round.actionTaken(.leave)
            #expect(!round.inProgress)
        }
    }
}

@Suite("Round with more than two players")
struct MoreThanTwoPlayerRoundTests {
    private func newRound() -> Round {
        Round(activePlayers: [true, true, true, false, false, false, false, false], firstToAct: 0)
    }

    @Test("Precondition")
    func precondition() {
        let round = newRound()
        #expect(round.playerToAct == 0)
        #expect(round.lastAggressiveActor == 0)
        #expect(round.inProgress)
        #expect(round.numActivePlayers == 3)
    }

    @Test("The player to act acts aggressively: last aggressive actor remains unchanged")
    func aggressiveKeepsLastAggressiveActor() {
        var round = newRound()
        round.actionTaken(.aggressive)
        #expect(round.lastAggressiveActor == 0)
    }

    @Test("The player to act acts aggressively: next player becomes the player to act")
    func aggressiveAdvancesToNextPlayer() {
        var round = newRound()
        round.actionTaken(.aggressive)
        #expect(round.playerToAct == 1)
    }

    @Test("The player to act acts aggressively: round is not over")
    func aggressiveKeepsRoundInProgress() {
        var round = newRound()
        round.actionTaken(.aggressive)
        #expect(round.inProgress)
    }

    @Test("The player to act acts aggressively: number of active players is unchanged")
    func aggressiveKeepsActivePlayerCount() {
        var round = newRound()
        round.actionTaken(.aggressive)
        #expect(round.numActivePlayers == 3)
    }

    @Test("The player to act acts aggressively and leaves: last aggressive actor remains unchanged")
    func aggressiveLeaveKeepsLastAggressiveActor() {
        var round = newRound()
        round.actionTaken([.aggressive, .leave])
        #expect(round.lastAggressiveActor == 0)
    }

    @Test("The player to act acts aggressively and leaves: next player becomes the player to act")
    func aggressiveLeaveAdvancesToNextPlayer() {
        var round = newRound()
        round.actionTaken([.aggressive, .leave])
        #expect(round.playerToAct == 1)
    }

    @Test("The player to act acts aggressively and leaves: round is not over")
    func aggressiveLeaveKeepsRoundInProgress() {
        var round = newRound()
        round.actionTaken([.aggressive, .leave])
        #expect(round.inProgress)
    }

    @Test("The player to act acts aggressively and leaves: one less active player")
    func aggressiveLeaveReducesActivePlayerCount() {
        var round = newRound()
        round.actionTaken([.aggressive, .leave])
        #expect(round.numActivePlayers == 2)
    }

    @Test("The player to act acts passively: last aggressive actor remains unchanged")
    func passiveKeepsLastAggressiveActor() {
        var round = newRound()
        round.actionTaken(.passive)
        #expect(round.lastAggressiveActor == 0)
    }

    @Test("The player to act acts passively: next player becomes the player to act")
    func passiveAdvancesToNextPlayer() {
        var round = newRound()
        round.actionTaken(.passive)
        #expect(round.playerToAct == 1)
    }

    @Test("The player to act acts passively: round is not over")
    func passiveKeepsRoundInProgress() {
        var round = newRound()
        round.actionTaken(.passive)
        #expect(round.inProgress)
    }

    @Test("The player to act acts passively: number of active players is unchanged")
    func passiveKeepsActivePlayerCount() {
        var round = newRound()
        round.actionTaken(.passive)
        #expect(round.numActivePlayers == 3)
    }

    @Test("The player to act acts passively and leaves: last aggressive actor remains unchanged")
    func passiveLeaveKeepsLastAggressiveActor() {
        var round = newRound()
        round.actionTaken([.passive, .leave])
        #expect(round.lastAggressiveActor == 0)
    }

    @Test("The player to act acts passively and leaves: next player becomes the player to act")
    func passiveLeaveAdvancesToNextPlayer() {
        var round = newRound()
        round.actionTaken([.passive, .leave])
        #expect(round.playerToAct == 1)
    }

    @Test("The player to act acts passively and leaves: round is not over")
    func passiveLeaveKeepsRoundInProgress() {
        var round = newRound()
        round.actionTaken([.passive, .leave])
        #expect(round.inProgress)
    }

    @Test("The player to act acts passively and leaves: one less active player")
    func passiveLeaveReducesActivePlayerCount() {
        var round = newRound()
        round.actionTaken([.passive, .leave])
        #expect(round.numActivePlayers == 2)
    }

    @Test("The player to act leaves: last aggressive actor remains unchanged")
    func leaveKeepsLastAggressiveActor() {
        var round = newRound()
        round.actionTaken(.leave)
        #expect(round.lastAggressiveActor == 0)
    }

    @Test("The player to act leaves: next player becomes the player to act")
    func leaveAdvancesToNextPlayer() {
        var round = newRound()
        round.actionTaken(.leave)
        #expect(round.playerToAct == 1)
    }

    @Test("The player to act leaves: round is not over")
    func leaveKeepsRoundInProgress() {
        var round = newRound()
        round.actionTaken(.leave)
        #expect(round.inProgress)
    }

    @Test("The player to act leaves: one less active player")
    func leaveReducesActivePlayerCount() {
        var round = newRound()
        round.actionTaken(.leave)
        #expect(round.numActivePlayers == 2)
    }
}

@Suite("Round with three players where the first acts first")
struct ThreePlayerFirstActsFirstTests {
    private func newRound() -> Round {
        Round(activePlayers: [true, true, true, false, false, false, false, false], firstToAct: 0)
    }

    @Test("A fresh round is in progress")
    func freshRoundIsInProgress() {
        #expect(newRound().inProgress)
    }

    @Test("The first two players leave: round is over")
    func firstTwoLeaveEndsRound() {
        var round = newRound()
        round.actionTaken(.leave)
        round.actionTaken(.leave)
        #expect(!round.inProgress)
        #expect(round.numActivePlayers == 1)
    }

    @Test("The first player leaves and the other two act passively: round is over")
    func leaveThenTwoPassivesEndsRound() {
        var round = newRound()
        round.actionTaken(.leave)
        round.actionTaken(.passive)
        round.actionTaken(.passive)
        #expect(!round.inProgress)
    }
}
