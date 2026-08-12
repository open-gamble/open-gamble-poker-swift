import Testing
@testable import OpenGamblePoker

private let defaultForcedBets: ForcedBets = (ante: nil, blinds: (small: 25, big: 50))

private func noopDeck() -> Deck {
    Deck { _ in }
}

private func makeCards(_ description: String) -> [Card] {
    description.split(whereSeparator: \.isWhitespace).map { part in
        let characters = Array(part.uppercased())
        let rank: CardRank
        switch characters[0] {
        case "2": rank = .two
        case "3": rank = .three
        case "4": rank = .four
        case "5": rank = .five
        case "6": rank = .six
        case "7": rank = .seven
        case "8": rank = .eight
        case "9": rank = .nine
        case "T": rank = .ten
        case "J": rank = .jack
        case "Q": rank = .queen
        case "K": rank = .king
        case "A": rank = .ace
        default: preconditionFailure("Invalid rank: \(characters[0])")
        }
        let suit: CardSuit
        switch characters[1] {
        case "S": suit = .spades
        case "H": suit = .hearts
        case "C": suit = .clubs
        case "D": suit = .diamonds
        default: preconditionFailure("Invalid suit: \(characters[1])")
        }
        return Card(rank: rank, suit: suit)
    }
}

private func prearrange(_ cards: [Card], into array: inout [Card]) {
    cards.enumerated().forEach { index, card in
        array[51 - index] = card
    }
}

private func shuffleForThreePlayersWithTwoWinners(_ array: inout [Card]) {
    prearrange(makeCards("2c 2c Kc 2c Kc 2c Ac Ac Ac Ac As"), into: &array)
}

private func shuffleForTwoPlayersWithFullHouseWinner(_ array: inout [Card]) {
    prearrange(makeCards("4s 4c Kc 5h Ac Ks 4d 2c 2s"), into: &array)
}

private func shuffleForTwoPlayersWithTwoPairsAndKickerWinner(_ array: inout [Card]) {
    prearrange(makeCards("3s Qc 4s Jc Ac Ah Kc Kd 2s"), into: &array)
}

private func shuffleForTwoPlayersWithThreeOfAKindAndKickerWinner(_ array: inout [Card]) {
    prearrange(makeCards("3s Qc 3c Jc 3h 3d Ac 7d 2s"), into: &array)
}

private func shuffleForTwoPlayersDraw(_ array: inout [Card]) {
    prearrange(makeCards("Td 9h Th 3c Qh Qc As Tc 5h"), into: &array)
}

private func shuffleForTwoPlayersDrawUsingOnlyCommunityCards(_ array: inout [Card]) {
    prearrange(makeCards("Td Js 3d 3s 6c Qc Ad 6s Ac"), into: &array)
}

private func threePlayers() -> SeatArray {
    var players: SeatArray = Array(repeating: nil, count: 9)
    players[0] = Player(total: 1000)
    players[1] = Player(total: 1000)
    players[2] = Player(total: 1000)
    return players
}

@Suite("Dealer")
struct DealerTests {
    @Suite("Starting the hand")
    struct StartingTheHandTests {
        @Suite("A hand with two players where the big blind has just enough to cover the blind")
        struct BigBlindJustCoversTests {
            @Test("Betting round should be in progress")
            func bettingRoundInProgress() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 50)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.bettingRoundInProgress())
            }

            @Test("Small blind should be allowed to fold, call, or raise")
            func smallBlindLegalActions() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 50)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                let actions = dealer.legalActions().action
                #expect(actions.contains(.fold))
                #expect(!actions.contains(.check))
                #expect(actions.contains(.call))
                #expect(!actions.contains(.bet))
                #expect(actions.contains(.raise))
            }

            @Test("Betting round should still be in progress after small blind calls and big blind should be allowed to fold or check")
            func bigBlindLegalActionsAfterCall() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 50)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()
                dealer.actionTaken(.call)

                let actions = dealer.legalActions().action
                #expect(actions.contains(.fold))
                #expect(actions.contains(.check))
                #expect(!actions.contains(.call))
                #expect(!actions.contains(.bet))
                #expect(!actions.contains(.raise))
            }

            @Test("Betting round should not be in progress after small blind calls and big blind checks")
            func bettingRoundEndsAfterCheck() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 50)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()
                dealer.actionTaken(.call)
                dealer.actionTaken(.check)

                #expect(!dealer.bettingRoundInProgress())
            }
        }

        @Suite("A hand with two players who can cover their blinds")
        struct TwoPlayersCoverBlindsTests {
            @Test("The button has posted the small blind")
            func buttonPostsSmallBlind() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.bettingRoundPlayers()[0]?.betSize == 25)
            }

            @Test("The other player has posted the big blind")
            func otherPlayerPostsBigBlind() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.bettingRoundPlayers()[1]?.betSize == 50)
            }

            @Test("The action is on the button")
            func actionIsOnButton() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.playerToAct() == 0)
            }
        }

        @Suite("A hand with two players who can't cover their blinds")
        struct TwoPlayersCannotCoverBlindsTests {
            @Test("The betting round is not in progress")
            func bettingRoundNotInProgress() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 20)
                players[1] = Player(total: 20)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(!dealer.bettingRoundInProgress())
                dealer.endBettingRound()
                #expect(!dealer.bettingRoundInProgress())
                #expect(dealer.bettingRoundsCompleted())
                #expect(dealer.roundOfBetting() == .river)
                dealer.showdown()
                #expect(!dealer.handInProgress())
            }
        }

        @Suite("A hand with more than two players")
        struct MoreThanTwoPlayersTests {
            @Test("The button+1 has posted the small blind")
            func buttonPlusOnePostsSmallBlind() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 100)
                players[2] = Player(total: 100)
                players[3] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.bettingRoundPlayers()[1]?.betSize == 25)
            }

            @Test("The button+2 has posted the big blind")
            func buttonPlusTwoPostsBigBlind() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 100)
                players[2] = Player(total: 100)
                players[3] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.bettingRoundPlayers()[2]?.betSize == 50)
            }

            @Test("The action is on the button+3")
            func actionIsOnButtonPlusThree() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 100)
                players[1] = Player(total: 100)
                players[2] = Player(total: 100)
                players[3] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()

                #expect(dealer.playerToAct() == 3)
            }
        }
    }

    @Suite("Ending the betting round")
    struct EndingTheBettingRoundTests {
        @Suite("There is two or more active players at the end of any betting round except river")
        struct TwoOrMoreActiveExceptRiverTests {
            @Test("Precondition")
            func precondition() {
                var dealer = makePlayedDealer(actions: [.call, .call, .check])
                let communityCards = dealer._communityCards

                #expect(!dealer.bettingRoundInProgress())
                #expect(dealer.numActivePlayers() > 2)
                #expect(dealer.roundOfBetting() != .river)
                #expect(communityCards.cards.isEmpty)
            }

            @Test("The next betting round begins")
            func nextBettingRoundBegins() {
                var dealer = makePlayedDealer(actions: [.call, .call, .check])
                dealer.endBettingRound()

                #expect(dealer.bettingRoundInProgress())
                #expect(dealer.roundOfBetting() == .flop)
                #expect(dealer._communityCards.cards.count == 3)
            }
        }

        @Suite("There is two or more active players at the end of river")
        struct TwoOrMoreActiveAtRiverTests {
            @Test("Precondition")
            func precondition() {
                var dealer = makeRiverDealer()

                #expect(!dealer.bettingRoundInProgress())
                #expect(dealer.roundOfBetting() == .river)
                #expect(dealer._communityCards.cards.count == 5)
            }

            @Suite("The betting round is ended")
            struct BettingRoundEndedTests {
                @Test("Precondition")
                func precondition() {
                    var dealer = makeRiverDealer()
                    dealer.endBettingRound()

                    #expect(!dealer.bettingRoundInProgress())
                    #expect(dealer.bettingRoundsCompleted())
                    #expect(dealer.roundOfBetting() == .river)
                }

                @Test("The hand is over")
                func handIsOver() {
                    var dealer = makeRiverDealer()
                    dealer.endBettingRound()
                    dealer.showdown()

                    #expect(!dealer.handInProgress())
                }
            }
        }

        @Suite("There is one or less active players at the end of a betting round and more than one player in all pots")
        struct OneOrLessActiveMultiplePotsTests {
            @Test("Precondition")
            func precondition() {
                var dealer = makePlayedDealer(actions: [.raise(1000), .call, .fold])

                #expect(!dealer.bettingRoundInProgress())
                #expect(dealer.numActivePlayers() < 1)
                #expect(dealer.roundOfBetting() != .river)
                #expect(dealer._communityCards.cards.isEmpty)
            }

            @Suite("The betting round is ended")
            struct BettingRoundEndedTests {
                @Test("The hand is over")
                func handIsOver() {
                    var dealer = makePlayedDealer(actions: [.raise(1000), .call, .fold])
                    dealer.endBettingRound()
                    dealer.showdown()

                    #expect(!dealer.handInProgress())
                }

                @Test("The undealt community cards (if any) are dealt")
                func undealtCommunityCardsAreDealt() {
                    var dealer = makePlayedDealer(actions: [.raise(1000), .call, .fold])
                    dealer.endBettingRound()
                    dealer.showdown()

                    #expect(dealer._communityCards.cards.count == 5)
                }
            }
        }

        @Suite("There is one or less active players at the end of a betting round and a single player in a single pot")
        struct OneOrLessActiveSinglePotTests {
            @Test("Precondition")
            func precondition() {
                var dealer = makePlayedDealer(actions: [.raise(1000), .fold, .fold])

                #expect(!dealer.bettingRoundInProgress())
                #expect(dealer.numActivePlayers() < 1)
                #expect(dealer.roundOfBetting() != .river)
                #expect(dealer._communityCards.cards.isEmpty)
            }

            @Suite("The betting round is ended")
            struct BettingRoundEndedTests {
                @Test("The hand is over")
                func handIsOver() {
                    var dealer = makePlayedDealer(actions: [.raise(1000), .fold, .fold])
                    dealer.endBettingRound()
                    dealer.showdown()

                    #expect(!dealer.handInProgress())
                }

                @Test("The undealt community cards (if any) are not dealt")
                func undealtCommunityCardsAreNotDealt() {
                    var dealer = makePlayedDealer(actions: [.raise(1000), .fold, .fold])
                    dealer.endBettingRound()
                    dealer.showdown()

                    #expect(dealer._communityCards.cards.isEmpty)
                }
            }
        }
    }

    @Suite("flop, someone folded preflop, now others fold, when 1 remains, the hand should be over")
    struct FlopFoldTests {
        @Test("Betting round is not in progress after last remaining player folds")
        func notInProgressAfterLastRemainingFolds() {
            var dealer = makePlayedDealer(actions: [.fold, .call, .check])
            #expect(!dealer.bettingRoundInProgress())
            dealer.endBettingRound()
            dealer.actionTaken(.fold)
            #expect(!dealer.bettingRoundInProgress())
        }

        @Suite("The betting round is ended")
        struct BettingRoundEndedTests {
            @Test("Player folds")
            func playerFolds() {
                var dealer = makePlayedDealer(actions: [.fold, .call, .check])
                dealer.endBettingRound()
                dealer.actionTaken(.fold)
                #expect(!dealer.bettingRoundInProgress())
            }
        }
    }

    @Suite("Showdown")
    struct ShowdownTests {
        @Suite("single pot single player")
        struct SinglePotSinglePlayerTests {
            @Test("Single winner")
            func singleWinner() {
                var dealer = makePlayedDealer(actions: [.raise(1000), .fold, .fold])
                dealer.endBettingRound()
                dealer.showdown()

                #expect(!dealer.handInProgress())
                #expect(dealer.bettingRoundPlayers()[0]?.stack == 1075)
            }
        }

        @Suite("single winner after full round")
        struct SingleWinnerAfterFullRoundTests {
            @Test("Pot has been divided")
            func potHasBeenDivided() {
                var dealer = makeFullRoundDealer(deck: noopDeck())
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 500)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 500)
                #expect(dealer.bettingRoundPlayers()[2]?.stack == 2000)
            }

            @Test("Reveal winner hand")
            func revealWinnerHand() {
                var dealer = makeFullRoundDealer(deck: noopDeck())
                dealer.showdown()

                let firstWinnerInFirstPot = dealer.winners()[0][0]
                #expect(firstWinnerInFirstPot.0 == 2)
                #expect(firstWinnerInFirstPot.1.ranking == .straightFlush)
                #expect(firstWinnerInFirstPot.1.strength == 8)
                #expect(firstWinnerInFirstPot.1.cards == [
                    Card(rank: .ten, suit: .spades),
                    Card(rank: .nine, suit: .spades),
                    Card(rank: .eight, suit: .spades),
                    Card(rank: .seven, suit: .spades),
                    Card(rank: .six, suit: .spades),
                ])
                #expect(firstWinnerInFirstPot.2 == (Card(rank: .ten, suit: .spades), Card(rank: .nine, suit: .spades)))
            }
        }

        @Suite("single three of a kind winner with help from kicker after full round")
        struct ThreeOfAKindWinnerTests {
            @Test("Pot has been divided")
            func potHasBeenDivided() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersWithThreeOfAKindAndKickerWinner))
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 1500)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 500)
            }
        }

        @Suite("single two pairs winner with help from kicker after full round")
        struct TwoPairsWinnerTests {
            @Test("Pot has been divided")
            func potHasBeenDivided() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersWithTwoPairsAndKickerWinner))
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 1500)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 500)
            }

            @Test("Reveal winner hand")
            func revealWinnerHand() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersWithTwoPairsAndKickerWinner))
                dealer.showdown()

                let firstWinnerInFirstPot = dealer.winners()[0][0]
                #expect(firstWinnerInFirstPot.0 == 0)
                #expect(firstWinnerInFirstPot.1.ranking == .twoPair)
                #expect(firstWinnerInFirstPot.1.strength == 368589)
                #expect(firstWinnerInFirstPot.1.cards == [
                    Card(rank: .ace, suit: .clubs),
                    Card(rank: .ace, suit: .hearts),
                    Card(rank: .king, suit: .clubs),
                    Card(rank: .king, suit: .diamonds),
                    Card(rank: .queen, suit: .clubs),
                ])
                #expect(firstWinnerInFirstPot.2 == (Card(rank: .three, suit: .spades), Card(rank: .queen, suit: .clubs)))
            }
        }

        @Suite("single winner with full house after full round")
        struct FullHouseWinnerTests {
            @Test("Pot has been divided")
            func potHasBeenDivided() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersWithFullHouseWinner))
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 1500)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 500)
            }

            @Test("Reveal winner hand")
            func revealWinnerHand() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersWithFullHouseWinner))
                dealer.showdown()

                let firstWinnerInFirstPot = dealer.winners()[0][0]
                #expect(firstWinnerInFirstPot.0 == 0)
                #expect(firstWinnerInFirstPot.1.ranking == .fullHouse)
                #expect(firstWinnerInFirstPot.1.strength == 57122)
                #expect(firstWinnerInFirstPot.1.cards == [
                    Card(rank: .four, suit: .spades),
                    Card(rank: .four, suit: .clubs),
                    Card(rank: .four, suit: .diamonds),
                    Card(rank: .two, suit: .clubs),
                    Card(rank: .two, suit: .spades),
                ])
                #expect(firstWinnerInFirstPot.2 == (Card(rank: .four, suit: .spades), Card(rank: .four, suit: .clubs)))
            }
        }

        @Suite("all players winners using community cards and hole cards")
        struct DrawWithHoleCardsTests {
            @Test("Pot has been divided equally")
            func potDividedEqually() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersDraw))
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 1000)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 1000)
            }
        }

        @Suite("all players winners using only community cards")
        struct DrawUsingOnlyCommunityCardsTests {
            @Test("Pot has been divided equally")
            func potDividedEqually() {
                var dealer = makeFullRoundTwoPlayerDealer(deck: Deck(shuffleAlgorithm: shuffleForTwoPlayersDrawUsingOnlyCommunityCards))
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 1000)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 1000)
            }
        }

        @Suite("two winners share odd pot")
        struct TwoWinnersShareOddPotTests {
            @Test("Pot has been divided")
            func potHasBeenDivided() {
                var dealer = makePlayedDealer(actions: [.raise(501), .call, .call], deck: Deck(shuffleAlgorithm: shuffleForThreePlayersWithTwoWinners))
                dealer.endBettingRound()
                dealRemainingStreets(&dealer)
                dealer.showdown()

                #expect(dealer.bettingRoundPlayers()[0]?.stack == 499)
                #expect(dealer.bettingRoundPlayers()[1]?.stack == 1251)
                #expect(dealer.bettingRoundPlayers()[2]?.stack == 1250)
            }
        }

        @Suite("multiple pots, multiple winners")
        struct MultiplePotsMultipleWinnersTests {
            @Test("Completing the hand does not crash")
            func completingHandDoesNotCrash() {
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 300)
                players[1] = Player(total: 200)
                players[2] = Player(total: 100)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: noopDeck(), communityCards: CommunityCards())
                dealer.startHand()
                dealer.actionTaken(.raise, bet: 300)
                dealer.actionTaken(.call)
                dealer.actionTaken(.call)
                dealer.endBettingRound()
            }
        }

        @Suite("Calling on the big blind does not cause a crash")
        struct CallingOnBigBlindTests {
            @Test("Calling on the big blind")
            func callingOnBigBlind() {
                var deck = Deck()
                var communityCards = CommunityCards()
                var players: SeatArray = Array(repeating: nil, count: 9)
                players[0] = Player(total: 1000)
                players[1] = Player(total: 1000)
                var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: deck, communityCards: communityCards)
                dealer.startHand()
                dealer.actionTaken(.call)
                dealer.actionTaken(.fold)
                dealer.endBettingRound()
                dealer.showdown()

                deck = Deck()
                communityCards = CommunityCards()
                dealer = Dealer(players: players, button: 1, forcedBets: defaultForcedBets, deck: deck, communityCards: communityCards)
                dealer.startHand()
            }
        }
    }
}

private enum TestAction {
    case fold
    case call
    case check
    case raise(Chips)
}

private func apply(_ actions: [TestAction], to dealer: inout Dealer) {
    for action in actions {
        switch action {
        case .fold:
            dealer.actionTaken(.fold)
        case .call:
            dealer.actionTaken(.call)
        case .check:
            dealer.actionTaken(.check)
        case .raise(let bet):
            dealer.actionTaken(.raise, bet: bet)
        }
    }
}

private func makePlayedDealer(actions: [TestAction], deck: Deck = noopDeck()) -> Dealer {
    let players = threePlayers()
    var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: deck, communityCards: CommunityCards())
    dealer.startHand()
    apply(actions, to: &dealer)
    return dealer
}

private func makeRiverDealer() -> Dealer {
    var dealer = makePlayedDealer(actions: [.call, .call, .check])
    dealer.endBettingRound()
    dealer.actionTaken(.check)
    dealer.actionTaken(.check)
    dealer.actionTaken(.check)
    dealer.endBettingRound()
    dealer.actionTaken(.check)
    dealer.actionTaken(.check)
    dealer.actionTaken(.check)
    dealer.endBettingRound()
    dealer.actionTaken(.check)
    dealer.actionTaken(.check)
    dealer.actionTaken(.check)
    return dealer
}

private func dealRemainingStreets(_ dealer: inout Dealer) {
    for _ in 0..<3 {
        while dealer.bettingRoundInProgress() {
            dealer.actionTaken(.check)
        }
        dealer.endBettingRound()
    }
}

private func makeFullRoundDealer(deck: Deck) -> Dealer {
    var dealer = makePlayedDealer(actions: [.raise(500), .call, .call], deck: deck)
    dealer.endBettingRound()
    dealRemainingStreets(&dealer)
    return dealer
}

private func makeFullRoundTwoPlayerDealer(deck: Deck) -> Dealer {
    var players: SeatArray = Array(repeating: nil, count: 9)
    players[0] = Player(total: 1000)
    players[1] = Player(total: 1000)
    var dealer = Dealer(players: players, button: 0, forcedBets: defaultForcedBets, deck: deck, communityCards: CommunityCards())
    dealer.startHand()
    dealer.actionTaken(.raise, bet: 500)
    dealer.actionTaken(.call)
    dealer.endBettingRound()
    dealRemainingStreets(&dealer)
    return dealer
}
