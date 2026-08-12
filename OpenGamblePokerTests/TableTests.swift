import Testing
@testable import OpenGamblePoker

private let defaultForcedBets: ForcedBets = (ante: nil, blinds: (small: 25, big: 50))

@Suite("Table")
struct TableTests {
    @Test("Table construction")
    func construction() {
        let table = Table(forcedBets: defaultForcedBets)
        #expect(table.seats().allSatisfy { $0 == nil })
        #expect(table.forcedBets().blinds.big == 50)
        #expect(table.forcedBets().blinds.small == 25)
        #expect(table.numSeats() == 9)
        #expect(!table.handInProgress())
    }

    @Test("Setting forced bets")
    func settingForcedBets() {
        var table = Table(forcedBets: defaultForcedBets)
        table.setForcedBets((ante: nil, blinds: (small: 100, big: 200)))
        #expect(table.forcedBets().blinds.big == 200)
        #expect(table.forcedBets().blinds.small == 100)
    }

    @Test("Moving the button between hands")
    func movingButtonBetweenHands() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(2, 2000)
        table.sitDown(3, 2000)
        table.sitDown(4, 2000)
        table.startHand()
        #expect(table.button() == 2)
        table.actionTaken(.fold)
        table.actionTaken(.fold)
        table.endBettingRound()
        table.showdown()
        #expect(!table.handInProgress())

        table.startHand()
        #expect(table.button() == 3)
    }

    @Suite("Adding/removing players")
    struct AddingRemovingPlayersTests {
        @Suite("A table with no hand in play")
        struct NoHandInPlayTests {
            @Suite("A player takes a seat")
            struct PlayerTakesSeatTests {
                @Test("That seat is taken")
                func seatTaken() {
                    var table = Table(forcedBets: defaultForcedBets)
                    table.sitDown(7, 1000)
                    #expect(table.seats()[7] != nil)
                }
            }
        }

        @Suite("A table with one player seated and no hand in play")
        struct OnePlayerSeatedTests {
            @Suite("That player stands up")
            struct PlayerStandsUpTests {
                @Test("The seat opens up")
                func seatOpens() {
                    var table = Table(forcedBets: defaultForcedBets)
                    table.sitDown(7, 1000)
                    table.standUp(7)
                    #expect(table.seats()[7] == nil)
                }
            }
        }

        @Suite("A table with three players active in the hand which is in progress")
        struct ThreePlayersActiveTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(4, 2000)
                table.sitDown(5, 2000)
                table.sitDown(6, 2000)
                table.startHand()
                return table
            }

            @Test("Precondition")
            func precondition() {
                let table = Self.makeTable()
                #expect(table.bettingRoundInProgress())
                #expect(table.playerToAct() == 4)
            }

            @Suite("One of them stands up")
            struct OneStandsUpTests {
                @Test("The betting round is still in progress")
                func roundStillInProgress() {
                    var table = ThreePlayersActiveTests.makeTable()
                    table.standUp(5)
                    #expect(table.bettingRoundInProgress())
                }
            }

            @Suite("Two of them stand up")
            struct TwoStandUpTests {
                @Test("Precondition")
                func precondition() {
                    var table = ThreePlayersActiveTests.makeTable()
                    table.standUp(4)
                    #expect(table.playerToAct() == 5)
                }

                @Suite("Second player stands up")
                struct SecondStandsUpTests {
                    @Test("The betting round is over")
                    func roundIsOver() {
                        var table = ThreePlayersActiveTests.makeTable()
                        table.standUp(4)
                        table.standUp(6)
                        #expect(!table.bettingRoundInProgress())
                    }
                }
            }
        }

        @Suite("A table with a few active players in a hand which is in progress")
        struct FewActivePlayersTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(4, 2000)
                table.sitDown(5, 2000)
                table.sitDown(6, 2000)
                table.startHand()
                return table
            }

            @Suite("A player stands up")
            struct PlayerStandsUpTests {
                @Test("His/her automatic action is set to fold")
                func autoFold() {
                    var table = FewActivePlayersTests.makeTable()
                    table.standUp(6)
                    #expect(table.automaticActions()[6] == .fold)
                }
            }

            @Suite("The player to act stands up")
            struct PlayerToActStandsUpTests {
                @Test("Precondition")
                func precondition() {
                    let table = FewActivePlayersTests.makeTable()
                    #expect(table.playerToAct() == 4)
                    #expect(table.numActivePlayers() == 3)
                }

                @Suite("Player stands up")
                struct PlayerStandsUpTests {
                    @Test("His action counts as a fold")
                    func countsAsFold() {
                        var table = FewActivePlayersTests.makeTable()
                        table.standUp(4)
                        #expect(table.playerToAct() == 5)
                        #expect(table.numActivePlayers() == 2)
                    }
                }
            }
        }
    }

    @Suite("Automatic actions")
    struct AutomaticActionsTests {
        @Suite("Three players sit down and the hand begins")
        struct ThreePlayersHandTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                return table
            }

            @Test("The legal actions for each player are appropriate")
            func legalActions() {
                let table = Self.makeTable()
                #expect(table.seats()[1]?.betSize == 0)
                #expect(table.seats()[2]?.betSize == 25)
                #expect(table.seats()[3]?.betSize == 50)

                var legal = table.legalAutomaticActions(1)
                #expect(legal.contains(.fold))
                #expect(!legal.contains(.checkFold))
                #expect(!legal.contains(.check))
                #expect(legal.contains(.call))
                #expect(legal.contains(.callAny))
                #expect(legal.contains(.allIn))

                legal = table.legalAutomaticActions(2)
                #expect(legal.contains(.fold))
                #expect(!legal.contains(.checkFold))
                #expect(!legal.contains(.check))
                #expect(legal.contains(.call))
                #expect(legal.contains(.callAny))
                #expect(legal.contains(.allIn))

                legal = table.legalAutomaticActions(3)
                #expect(legal.contains(.fold))
                #expect(legal.contains(.checkFold))
                #expect(legal.contains(.check))
                #expect(!legal.contains(.call))
                #expect(legal.contains(.callAny))
                #expect(legal.contains(.allIn))
            }
        }

        @Suite("A table with a game that has just begun")
        struct GameJustBegunTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                return table
            }

            @Suite("SB and BB set their automatic actions")
            struct SBAndBBAutomaticActionsTests {
                @Test("The table state reflects that")
                func stateReflected() {
                    var table = GameJustBegunTests.makeTable()
                    table.setAutomaticAction(2, .call)
                    table.setAutomaticAction(3, .allIn)
                    #expect(table.automaticActions()[2] == .call)
                    #expect(table.automaticActions()[3] == .allIn)
                }

                @Test("Reset automatic action")
                func reset() {
                    var table = GameJustBegunTests.makeTable()
                    table.setAutomaticAction(2, .call)
                    table.setAutomaticAction(2, nil)
                    #expect(table.automaticActions()[2] == nil)
                }
            }
        }

        @Suite("A table where SB and BB have set their automatic actions to call/check")
        struct SBCallBBCheckTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                table.setAutomaticAction(2, .call)
                table.setAutomaticAction(3, .check)
                return table
            }

            @Suite("The player to act calls")
            struct PlayerToActCallsTests {
                @Test("The automatic actions play out")
                func playOut() {
                    var table = SBCallBBCheckTests.makeTable()
                    table.actionTaken(.call)
                    #expect(table.seats()[1]?.betSize == 50)
                    #expect(table.seats()[2]?.betSize == 50)
                    #expect(table.seats()[3]?.betSize == 50)
                }

                @Test("The betting round ends")
                func roundEnds() {
                    var table = SBCallBBCheckTests.makeTable()
                    table.actionTaken(.call)
                    #expect(!table.bettingRoundInProgress())
                }
            }
        }

        @Suite("A table where a player's automatic action has been taken")
        struct AutomaticActionTakenTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                table.setAutomaticAction(2, .call)
                table.actionTaken(.call)
                return table
            }

            @Test("Precondition")
            func precondition() {
                let table = Self.makeTable()
                #expect(table.playerToAct() == 3)
            }

            @Suite("Action gets back to him/her")
            struct ActionGetsBackTests {
                @Test("He/she is the player to act")
                func playerToAct() {
                    var table = AutomaticActionTakenTests.makeTable()
                    table.actionTaken(.raise, bet: 200)
                    table.actionTaken(.call)
                    #expect(table.bettingRoundInProgress())
                    #expect(table.playerToAct() == 2)
                }
            }
        }

        @Suite("A table where a player's automatic action is set to check_fold")
        struct CheckFoldTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                table.setAutomaticAction(3, .checkFold)
                return table
            }

            @Suite("Some other player raises")
            struct OtherRaisesTests {
                @Test("His automatic action falls back to fold")
                func fallsBackToFold() {
                    var table = CheckFoldTests.makeTable()
                    table.actionTaken(.raise, bet: 200)
                    #expect(table.automaticActions()[3] == .fold)
                }
            }

            @Suite("That doesn't happen")
            struct OtherDoesNotRaiseTests {
                @Test("His/her automatic action remains the same")
                func remains() {
                    var table = CheckFoldTests.makeTable()
                    table.actionTaken(.call)
                    #expect(table.automaticActions()[3] == .checkFold)
                }
            }
        }

        @Suite("A table where a player's automatic action is set to check")
        struct CheckTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                table.setAutomaticAction(3, .check)
                return table
            }

            @Suite("Some other player raises")
            struct OtherRaisesTests {
                @Test("His/her automatic action gets removed")
                func removed() {
                    var table = CheckTests.makeTable()
                    table.actionTaken(.raise, bet: 200)
                    #expect(table.automaticActions()[3] == nil)
                }
            }

            @Suite("That doesn't happen")
            struct OtherDoesNotRaiseTests {
                @Test("His/her automatic action remains the same")
                func remains() {
                    var table = CheckTests.makeTable()
                    table.actionTaken(.call)
                    #expect(table.automaticActions()[3] == .check)
                }
            }
        }

        @Suite("A table where a player's automatic action is set to call_any")
        struct CallAnyTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                table.setAutomaticAction(3, .callAny)
                return table
            }

            @Suite("Some other player goes all-in")
            struct OtherAllInTests {
                @Test("His automatic action falls back to call")
                func fallsBackToCall() {
                    var table = CallAnyTests.makeTable()
                    table.actionTaken(.raise, bet: 2000)
                    #expect(table.automaticActions()[3] == .call)
                }
            }

            @Suite("That doesn't happen")
            struct OtherDoesNotAllInTests {
                @Test("His/her automatic action remains the same")
                func remains() {
                    var table = CallAnyTests.makeTable()
                    table.actionTaken(.call)
                    #expect(table.automaticActions()[3] == .callAny)
                }
            }
        }

        @Suite("A table where a hand has just begun")
        struct HandJustBegunTests {
            private static func makeTable() -> Table {
                var table = Table(forcedBets: defaultForcedBets)
                table.sitDown(1, 2000)
                table.sitDown(2, 2000)
                table.sitDown(3, 2000)
                table.startHand()
                return table
            }

            @Suite("A player sets his automatic action to fold and it gets triggered")
            struct FoldTriggeredTests {
                @Test("He/she folded")
                func folded() {
                    var table = HandJustBegunTests.makeTable()
                    table.setAutomaticAction(2, .fold)
                    table.actionTaken(.call)
                    #expect(table.handPlayers().filter { $0 != nil }.count == 2)
                }
            }

            @Suite("A player sets his automatic action to check_fold and it gets triggered")
            struct CheckFoldTriggeredTests {
                @Test("Precondition")
                func precondition() {
                    let table = HandJustBegunTests.makeTable()
                    #expect(table.seats()[3]?.betSize == 50)
                }

                @Suite("Actions setup")
                struct ActionsSetupTests {
                    @Test("He/she checked")
                    func checked() {
                        var table = HandJustBegunTests.makeTable()
                        table.setAutomaticAction(3, .checkFold)
                        table.actionTaken(.call)
                        table.actionTaken(.call)
                        #expect(!table.bettingRoundInProgress())
                        #expect(table.seats()[3]?.betSize == 50)
                    }
                }
            }

            @Suite("A player sets his automatic action to check and it gets triggered")
            struct CheckTriggeredTests {
                @Test("Precondition")
                func precondition() {
                    let table = HandJustBegunTests.makeTable()
                    #expect(table.seats()[3]?.betSize == 50)
                }

                @Suite("Actions setup")
                struct ActionsSetupTests {
                    @Test("He/she checked")
                    func checked() {
                        var table = HandJustBegunTests.makeTable()
                        table.setAutomaticAction(3, .check)
                        table.actionTaken(.call)
                        table.actionTaken(.call)
                        #expect(!table.bettingRoundInProgress())
                        #expect(table.seats()[3]?.betSize == 50)
                    }
                }
            }

            @Suite("A player sets his automatic action to call and it gets triggered")
            struct CallTriggeredTests {
                @Test("Precondition")
                func precondition() {
                    let table = HandJustBegunTests.makeTable()
                    #expect(table.seats()[2]?.betSize == 25)
                }

                @Suite("Actions setup")
                struct ActionsSetupTests {
                    @Test("He/she called")
                    func called() {
                        var table = HandJustBegunTests.makeTable()
                        table.setAutomaticAction(2, .call)
                        table.actionTaken(.call)
                        #expect(table.playerToAct() == 3)
                        #expect(table.seats()[2]?.betSize == 50)
                    }
                }
            }

            @Suite("A player sets his automatic action to call_any and it gets triggered")
            struct CallAnyTriggeredTests {
                @Test("Precondition")
                func precondition() {
                    let table = HandJustBegunTests.makeTable()
                    #expect(table.seats()[2]?.betSize == 25)
                }

                @Suite("Actions setup")
                struct ActionsSetupTests {
                    @Test("He/she called")
                    func called() {
                        var table = HandJustBegunTests.makeTable()
                        table.setAutomaticAction(2, .callAny)
                        table.actionTaken(.call)
                        #expect(table.playerToAct() == 3)
                        #expect(table.seats()[2]?.betSize == 50)
                    }
                }
            }

            @Suite("A player sets his automatic action to all_in and it gets triggered")
            struct AllInTriggeredTests {
                @Test("Precondition")
                func precondition() {
                    let table = HandJustBegunTests.makeTable()
                    #expect(table.playerToAct() == 1)
                    #expect(table.seats()[2]?.betSize == 25)
                }

                @Suite("Actions setup")
                struct ActionsSetupTests {
                    @Test("He/she called (any)")
                    func called() {
                        var table = HandJustBegunTests.makeTable()
                        table.setAutomaticAction(2, .allIn)
                        table.actionTaken(.call)
                        #expect(table.playerToAct() == 3)
                        #expect(table.seats()[2]?.betSize == 2000)
                    }
                }
            }
        }
    }

    @Test("When second to last player stands up, the hand ends")
    func secondToLastPlayerStandsUpEndsHand() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(0, 1000)
        table.sitDown(1, 1000)
        table.sitDown(2, 1000)
        table.startHand()

        #expect(table.playerToAct() == 0)
        #expect(table.seats()[0]?.betSize == 0)
        #expect(table.seats()[1]?.betSize == 25)
        #expect(table.seats()[2]?.betSize == 50)
        #expect(table.button() == 0)

        table.standUp(1)
        table.standUp(2)
        table.sitDown(1, 1000)
        table.sitDown(2, 2000)

        #expect(!table.bettingRoundInProgress())
        table.endBettingRound()
        #expect(table.seats()[0]?.stack == 950)

        table.showdown()
        #expect(!table.handInProgress())
        #expect(table.seats()[0]?.stack == 1075)

        table.startHand()
        #expect(table.button() == 1)
        table.standUp(2)
        table.standUp(0)
        #expect(!table.bettingRoundInProgress())
        #expect(table.handInProgress())
        table.endBettingRound()
        #expect(table.handInProgress())
        table.showdown()
        #expect(!table.handInProgress())
    }

    @Test("Testing the special case")
    func specialCase() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(0, 1000)
        table.sitDown(1, 1000)
        table.sitDown(2, 1000)
        table.standUp(2)
        table.sitDown(2, 1000)
        table.startHand()
        table.setAutomaticAction(1, .callAny)
        table.setAutomaticAction(2, .callAny)
        table.actionTaken(.call)
        #expect(!table.bettingRoundInProgress())
    }

    @Test("Community cards get reset when a new hand begins")
    func communityCardsReset() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(0, 1000)
        table.sitDown(1, 1000)
        table.startHand()
        table.actionTaken(.call)
        table.actionTaken(.check)
        table.endBettingRound()
        table.actionTaken(.fold)
        table.endBettingRound()
        #expect(table.bettingRoundsCompleted())
        table.showdown()
        table.startHand()
        #expect(table.communityCards().cards.count == 0)
    }

    @Test("Setting the button manually works on the first, as well as the subsequent hands")
    func manualButtonFirstAndSubsequentHands() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(0, 1000)
        table.sitDown(3, 1000)
        table.sitDown(5, 1000)
        table.sitDown(8, 1000)

        table.startHand(seat: 8)
        #expect(table.button() == 8)
        table.actionTaken(.fold)
        table.actionTaken(.fold)
        table.actionTaken(.fold)
        table.endBettingRound()
        table.showdown()

        table.startHand(seat: 5)
        #expect(table.button() == 5)
    }

    @Test("Button wraps around correctly when moved from the last position")
    func buttonWrapsAround() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(0, 1000)
        table.sitDown(3, 1000)
        table.sitDown(5, 1000)
        table.sitDown(8, 1000)

        table.startHand(seat: 8)
        #expect(table.button() == 8)
        table.actionTaken(.fold)
        table.actionTaken(.fold)
        table.actionTaken(.fold)
        table.endBettingRound()
        table.showdown()

        table.startHand()
        #expect(table.button() == 0)
    }

    @Test("No crash when the player to act stands up with one player remaining")
    func noCrashWhenPlayerToActStandsUp() {
        var table = Table(forcedBets: defaultForcedBets)
        table.sitDown(1, 1000)
        table.sitDown(8, 1000)
        table.startHand()
        table.standUp(1)
    }

    @Suite("Betting round ends when only a single active player remains")
    struct SingleActivePlayerRemainingTests {
        @Test("Correct behavior after action_taken")
        func afterActionTaken() {
            var table = Table(forcedBets: defaultForcedBets)
            table.sitDown(1, 1000)
            table.sitDown(5, 1000)
            table.sitDown(8, 1000)
            table.startHand()
            #expect(table.playerToAct() == 1)
            table.standUp(8)
            table.actionTaken(.fold)
            #expect(!table.bettingRoundInProgress())
        }

        @Test("Correct behavior after stand_up")
        func afterStandUp() {
            var table = Table(forcedBets: defaultForcedBets)
            table.sitDown(1, 1000)
            table.sitDown(5, 1000)
            table.sitDown(8, 1000)
            table.startHand()
            #expect(table.playerToAct() == 1)
            table.actionTaken(.fold)
            table.standUp(8)
            #expect(!table.bettingRoundInProgress())
        }

        @Test("Heads-up preflop first-to-act all-in does not cause the other player to automatically act passively")
        func headsUpAllInNoPassive() {
            var table = Table(forcedBets: defaultForcedBets)
            table.sitDown(0, 1000)
            table.sitDown(1, 1000)
            table.startHand()
            table.actionTaken(.raise, bet: 1000)
            table.actionTaken(.fold)
            #expect(!table.bettingRoundInProgress())
        }

        @Test("(addendum) Players who stood up or folded do not count as active")
        func stoodUpOrFoldedDoNotCount() {
            var table = Table(forcedBets: defaultForcedBets)
            table.sitDown(0, 1000)
            table.sitDown(1, 1000)
            table.sitDown(2, 1000)
            table.sitDown(3, 1000)
            table.startHand()
            table.standUp(3)
            table.standUp(2)
            table.actionTaken(.fold)
            #expect(!table.bettingRoundInProgress())
        }
    }
}
