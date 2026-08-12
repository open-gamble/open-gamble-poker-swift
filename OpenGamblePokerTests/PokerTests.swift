import Testing
@testable import OpenGamblePoker

@Suite("Poker facade")
struct PokerTests {
    private static func makePoker() -> Poker.Table {
        let poker = Poker.Table(forcedBets: Poker.ForcedBets(smallBlind: 50, bigBlind: 100))
        poker.sitDown(0, 2000)
        poker.sitDown(1, 2000)
        poker.sitDown(2, 2000)
        return poker
    }

    private static func makeStartedPoker() -> Poker.Table {
        let poker = makePoker()
        poker.startHand()
        return poker
    }

    private static func expectedSeats(_ entries: [Poker.Seat?]) -> [Poker.Seat?] {
        var result: [Poker.Seat?] = Array(repeating: nil, count: 9)
        for (index, entry) in entries.enumerated() {
            result[index] = entry
        }
        return result
    }

    private static func seat(_ totalChips: Int, _ stack: Int, _ betSize: Int) -> Poker.Seat {
        Poker.Seat(totalChips: totalChips, stack: stack, betSize: betSize)
    }

    @Test("Set forced bets")
    func setForcedBets() {
        let poker = Self.makePoker()
        poker.setForcedBets(Poker.ForcedBets(smallBlind: 100, bigBlind: 200))
        #expect(poker.forcedBets() == Poker.ForcedBets(smallBlind: 100, bigBlind: 200, ante: 0))
    }

    @Test("Number of seats")
    func numSeats() {
        let poker = Self.makePoker()
        #expect(poker.numSeats() == 9)
    }

    @Test("Stand up")
    func standUp() {
        let poker = Self.makePoker()
        #expect(poker.seats() == Self.expectedSeats([
            Self.seat(2000, 2000, 0),
            Self.seat(2000, 2000, 0),
            Self.seat(2000, 2000, 0),
        ]))

        poker.standUp(2)

        #expect(poker.seats() == Self.expectedSeats([
            Self.seat(2000, 2000, 0),
            Self.seat(2000, 2000, 0),
            nil,
        ]))
    }

    @Suite("Hand in progress")
    struct HandInProgressTests {
        @Test("Player to act")
        func playerToAct() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.playerToAct() == 0)
        }

        @Test("Button")
        func button() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.button() == 0)
        }

        @Test("Seats")
        func seats() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.seats() == PokerTests.expectedSeats([
                PokerTests.seat(2000, 2000, 0),
                PokerTests.seat(2000, 1950, 50),
                PokerTests.seat(2000, 1900, 100),
            ]))
        }

        @Test("Hand players")
        func handPlayers() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.handPlayers() == PokerTests.expectedSeats([
                PokerTests.seat(2000, 2000, 0),
                PokerTests.seat(2000, 1950, 50),
                PokerTests.seat(2000, 1900, 100),
            ]))
        }

        @Test("Number of active players")
        func numActivePlayers() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.numActivePlayers() == 3)
        }

        @Test("Forced bets")
        func forcedBets() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.forcedBets() == Poker.ForcedBets(smallBlind: 50, bigBlind: 100, ante: 0))
        }

        @Test("Hand in progress")
        func isHandInProgress() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.isHandInProgress())
        }

        @Test("Betting round in progress")
        func isBettingRoundInProgress() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.isBettingRoundInProgress())
        }

        @Test("Betting rounds completed")
        func areBettingRoundsCompleted() {
            let poker = PokerTests.makeStartedPoker()
            #expect(!poker.areBettingRoundsCompleted())
        }

        @Test("Round of betting")
        func roundOfBetting() {
            let poker = PokerTests.makeStartedPoker()
            #expect(poker.roundOfBetting() == .preflop)
        }

        @Test("Legal actions")
        func legalActions() {
            let poker = PokerTests.makeStartedPoker()
            let legal = poker.legalActions()
            #expect(legal.actions == [.fold, .call, .raise])
            #expect(legal.chipRange == ChipRange(min: 200, max: 2000))
        }

        @Test("Folded bet is not excluded from table players")
        func foldedBetNotExcluded() {
            let poker = PokerTests.makeStartedPoker()
            poker.actionTaken(.call)
            poker.actionTaken(.fold)

            #expect(poker.seats() == PokerTests.expectedSeats([
                PokerTests.seat(2000, 1900, 100),
                PokerTests.seat(2000, 1950, 50),
                PokerTests.seat(2000, 1900, 100),
            ]))

            #expect(poker.handPlayers() == PokerTests.expectedSeats([
                PokerTests.seat(2000, 1900, 100),
                nil,
                PokerTests.seat(2000, 1900, 100),
            ]))
        }

        @Test("Bet is cleared from folding table player after ending betting round")
        func betClearedFromFoldingTablePlayer() {
            let poker = PokerTests.makeStartedPoker()
            poker.actionTaken(.call)
            poker.actionTaken(.fold)
            poker.actionTaken(.check)
            poker.endBettingRound()

            #expect(poker.seats()[1]?.betSize == 0)
        }

        @Suite("After first betting round")
        struct AfterFirstBettingRoundTests {
            private static func makePoker() -> Poker.Table {
                let poker = PokerTests.makeStartedPoker()
                poker.actionTaken(.call)
                poker.actionTaken(.call)
                poker.actionTaken(.check)
                poker.endBettingRound()
                return poker
            }

            @Test("Pots")
            func pots() {
                let poker = Self.makePoker()
                #expect(poker.pots().count == 1)
                #expect(poker.pots()[0].size == 300)
                #expect(poker.pots()[0].eligiblePlayers == [0, 1, 2])
            }

            @Test("Community cards")
            func communityCards() {
                let poker = Self.makePoker()
                let cards = poker.communityCards()
                #expect(cards.count == 3)
                let validSuits: Set<Poker.Card.Suit> = [.clubs, .diamonds, .hearts, .spades]
                let validRanks: Set<Poker.Card.Rank> = [
                    .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace,
                ]
                for card in cards {
                    #expect(validSuits.contains(card.suit))
                    #expect(validRanks.contains(card.rank))
                }
            }

            @Test("Hole cards")
            func holeCards() {
                let poker = Self.makePoker()
                let holeCards = poker.holeCards()
                #expect(holeCards.count == 9)
                let validSuits: Set<Poker.Card.Suit> = [.clubs, .diamonds, .hearts, .spades]
                let validRanks: Set<Poker.Card.Rank> = [
                    .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace,
                ]
                for cards in holeCards {
                    if let cards {
                        #expect(cards.count == 2)
                        for card in cards {
                            #expect(validSuits.contains(card.suit))
                            #expect(validRanks.contains(card.rank))
                        }
                    }
                }
            }

            @Test("Can set automatic actions")
            func canSetAutomaticActions() {
                let poker = Self.makePoker()
                #expect(poker.canSetAutomaticActions(2))
            }

            @Test("Legal automatic actions")
            func legalAutomaticActions() {
                let poker = Self.makePoker()
                #expect(poker.legalAutomaticActions(2) == [.fold, .checkFold, .check, .callAny, .allIn])
            }

            @Test("Set automatic action")
            func setAutomaticAction() {
                let poker = Self.makePoker()
                poker.setAutomaticAction(2, .callAny)
                #expect(poker.automaticActions() == [
                    nil, nil, .callAny, nil, nil, nil, nil, nil, nil,
                ])
            }

            @Test("Reset automatic action")
            func resetAutomaticAction() {
                let poker = Self.makePoker()
                poker.setAutomaticAction(2, .callAny)
                poker.setAutomaticAction(2, nil)
                #expect(poker.automaticActions() == [
                    nil, nil, nil, nil, nil, nil, nil, nil, nil,
                ])
            }

            @Suite("After all betting rounds")
            struct AfterAllBettingRoundsTests {
                private static func makePoker() -> Poker.Table {
                    let poker = AfterFirstBettingRoundTests.makePoker()
                    for _ in 0..<3 {
                        poker.actionTaken(.check)
                        poker.actionTaken(.check)
                        poker.actionTaken(.check)
                        poker.endBettingRound()
                    }
                    return poker
                }

                @Test("Showdown")
                func showdown() {
                    let poker = Self.makePoker()
                    #expect(poker.isHandInProgress())
                    poker.showdown()
                    #expect(!poker.isHandInProgress())
                }

                @Suite("Starting new round")
                struct StartingNewRoundTests {
                    @Test("Expect dealer button to move")
                    func buttonMoves() {
                        let poker = AfterAllBettingRoundsTests.makePoker()
                        poker.showdown()
                        poker.startHand()
                        #expect(poker.button() == 1)
                        #expect(poker.playerToAct() == 1)
                    }

                    @Test("Set dealer explicitly")
                    func setDealerExplicitly() {
                        let poker = AfterAllBettingRoundsTests.makePoker()
                        poker.showdown()
                        poker.startHand(seat: 2)
                        #expect(poker.button() == 2)
                        #expect(poker.playerToAct() == 2)
                    }

                    @Test("Setting dealer explicitly to non hand player should reset dealer")
                    func invalidSeatResets() {
                        let poker = AfterAllBettingRoundsTests.makePoker()
                        poker.showdown()
                        poker.startHand(seat: 10)
                        #expect(poker.button() == 0)
                        #expect(poker.playerToAct() == 0)
                    }
                }
            }
        }
    }
}
