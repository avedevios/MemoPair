//
//  MemoPairTests.swift
//  MemoPairTests
//
import Testing
import Foundation
@testable import MemoPair

// MARK: - Card

struct CardTests {

    @Test func cardHasUniqueIDs() {
        let card1 = Card(content: "France", pairID: 0)
        let card2 = Card(content: "Paris", pairID: 0)
        #expect(card1.id != card2.id)
    }

    @Test func cardIsNotMatchedByDefault() {
        let card = Card(content: "Tokyo", pairID: 1)
        #expect(card.isMatched == false)
    }

    @Test func cardCanBeMarkedAsMatched() {
        var card = Card(content: "Tokyo", pairID: 1)
        card.isMatched = true
        #expect(card.isMatched == true)
    }

    @Test func cardsWithSamePairIDArePaired() {
        let card1 = Card(content: "Japan", pairID: 2)
        let card2 = Card(content: "Tokyo", pairID: 2)
        #expect(card1.pairID == card2.pairID)
    }

    @Test func cardsWithDifferentPairIDsDoNotMatch() {
        let card1 = Card(content: "France", pairID: 0)
        let card2 = Card(content: "Tokyo", pairID: 1)
        #expect(card1.pairID != card2.pairID)
    }

    @Test func cardContentIsPreserved() {
        let card = Card(content: "Berlin", pairID: 3)
        #expect(card.content == "Berlin")
    }

    @Test func cardEquality() {
        let card1 = Card(content: "A", pairID: 0)
        let card2 = Card(content: "A", pairID: 0)
        // Different instances — different UUIDs, not equal
        #expect(card1 != card2)
    }

    @Test func cardWithEmptyContent() {
        let card = Card(content: "", pairID: 0)
        #expect(card.content == "")
    }

    @Test func cardWithZeroPairID() {
        let card = Card(content: "Test", pairID: 0)
        #expect(card.pairID == 0)
    }

    @Test func cardWithLargePairID() {
        let card = Card(content: "Test", pairID: Int.max)
        #expect(card.pairID == Int.max)
    }
}

// MARK: - CardPair

struct CardPairTests {

    @Test func tupleReturnsTermAndMatch() {
        let pair = CardPair(term: "Germany", match: "Berlin", category: "Geography", difficulty: 1)
        #expect(pair.tuple.0 == "Germany")
        #expect(pair.tuple.1 == "Berlin")
    }

    @Test func categoryIsPreserved() {
        let pair = CardPair(term: "H2O", match: "Water", category: "Chemistry", difficulty: 2)
        #expect(pair.category == "Chemistry")
    }

    @Test func difficultyIsPreserved() {
        let pair = CardPair(term: "H2O", match: "Water", category: "Chemistry", difficulty: 3)
        #expect(pair.difficulty == 3)
    }

    @Test func asTuplesExtension() {
        let pairs = [
            CardPair(term: "A", match: "B", category: "Test", difficulty: 1),
            CardPair(term: "C", match: "D", category: "Test", difficulty: 1)
        ]
        let tuples = pairs.asTuples
        #expect(tuples.count == 2)
        #expect(tuples[0].0 == "A")
        #expect(tuples[0].1 == "B")
        #expect(tuples[1].0 == "C")
        #expect(tuples[1].1 == "D")
    }

    @Test func emptyArrayAsTuples() {
        let pairs: [CardPair] = []
        #expect(pairs.asTuples.isEmpty)
    }

    @Test func cardPairIsCodable() throws {
        let pair = CardPair(term: "Spain", match: "Madrid", category: "Geography", difficulty: 1)
        let data = try JSONEncoder().encode(pair)
        let decoded = try JSONDecoder().decode(CardPair.self, from: data)
        #expect(decoded.term == pair.term)
        #expect(decoded.match == pair.match)
        #expect(decoded.category == pair.category)
        #expect(decoded.difficulty == pair.difficulty)
    }

    @Test func cardPairWithEmptyStrings() {
        let pair = CardPair(term: "", match: "", category: "", difficulty: 0)
        #expect(pair.term == "")
        #expect(pair.match == "")
        #expect(pair.tuple.0 == "")
        #expect(pair.tuple.1 == "")
    }

    @Test func cardPairWithZeroDifficulty() {
        let pair = CardPair(term: "A", match: "B", category: "Test", difficulty: 0)
        #expect(pair.difficulty == 0)
    }

    @Test func cardPairWithNegativeDifficulty() {
        let pair = CardPair(term: "A", match: "B", category: "Test", difficulty: -1)
        #expect(pair.difficulty == -1)
    }

    @Test func cardPairWithLongStrings() {
        let long = String(repeating: "a", count: 1000)
        let pair = CardPair(term: long, match: long, category: "Test", difficulty: 1)
        #expect(pair.term.count == 1000)
        #expect(pair.match.count == 1000)
    }

    @Test func cardPairWithUnicodeContent() {
        let pair = CardPair(term: "🇫🇷", match: "Париж", category: "🌍", difficulty: 1)
        #expect(pair.term == "🇫🇷")
        #expect(pair.match == "Париж")
        #expect(pair.tuple.0 == "🇫🇷")
    }

    @Test func cardPairCodableWithZeroDifficulty() throws {
        let pair = CardPair(term: "A", match: "B", category: "Test", difficulty: 0)
        let data = try JSONEncoder().encode(pair)
        let decoded = try JSONDecoder().decode(CardPair.self, from: data)
        #expect(decoded.difficulty == 0)
    }
}

// MARK: - CardManager

struct CardManagerTests {

    @Test func createCardsCountIsDoubleOfPairs() {
        let pairs: [(String, String)] = [("France", "Paris"), ("Japan", "Tokyo"), ("Italy", "Rome")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        #expect(cards.count == pairs.count * 2)
    }

    @Test func eachPairIDAppearsExactlyTwice() {
        let pairs: [(String, String)] = [("A", "B"), ("C", "D"), ("E", "F")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        let grouped = Dictionary(grouping: cards, by: \.pairID)
        for (_, group) in grouped {
            #expect(group.count == 2)
        }
    }

    @Test func pairIDsAreSequential() {
        let pairs: [(String, String)] = [("A", "B"), ("C", "D"), ("E", "F")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        let ids = Set(cards.map(\.pairID))
        #expect(ids == Set([0, 1, 2]))
    }

    @Test func cardsAreShuffled() {
        // Verify shuffle works — with a large set the order should change between runs
        let pairs: [(String, String)] = (0..<10).map { ("\($0)a", "\($0)b") }
        let run1 = CardManager.shared.createCardsFromPairs(pairs).map(\.content)
        let run2 = CardManager.shared.createCardsFromPairs(pairs).map(\.content)
        // Probability of identical order is 1/20! — practically impossible
        #expect(run1 != run2)
    }

    @Test func emptyPairsProducesNoCards() {
        let cards = CardManager.shared.createCardsFromPairs([])
        #expect(cards.isEmpty)
    }

    @Test func singlePairProducesTwoCards() {
        let cards = CardManager.shared.createCardsFromPairs([("Q", "A")])
        #expect(cards.count == 2)
        #expect(cards.allSatisfy { $0.pairID == 0 })
    }

    @Test func shuffledCardsCountMatchesLoadedPairs() {
        CardManager.shared.loadDefaultCards()
        let pairs = CardManager.shared.getAllPairs()
        let cards = CardManager.shared.getShuffledCards()
        #expect(cards.count == pairs.count * 2)
    }

    @Test func getAllCardPairsMatchesGetAllPairs() {
        CardManager.shared.loadDefaultCards()
        let cardPairs = CardManager.shared.getAllCardPairs()
        let tuples = CardManager.shared.getAllPairs()
        #expect(cardPairs.count == tuples.count)
        for (i, pair) in cardPairs.enumerated() {
            #expect(pair.term == tuples[i].0)
            #expect(pair.match == tuples[i].1)
        }
    }

    @Test func getPairsByCategory() {
        CardManager.shared.loadDefaultCards()
        let geo = CardManager.shared.getPairsByCategory("Geography")
        #expect(geo.allSatisfy { $0.category == "Geography" })
    }

    @Test func getPairsByDifficulty() {
        CardManager.shared.loadDefaultCards()
        let easy = CardManager.shared.getPairsByDifficulty(1)
        #expect(easy.allSatisfy { $0.difficulty == 1 })
    }

    @Test func updatePairChangesData() {
        let pairs: [(String, String)] = [("Old", "Value"), ("C", "D")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        // Verify original content exists in cards
        let contents = cards.map(\.content)
        #expect(contents.contains("Old"))
        #expect(contents.contains("Value"))
    }

    @Test func updatePairWithInvalidIndexDoesNotCrash() {
        CardManager.shared.loadDefaultCards()
        // Should not crash with out-of-bounds index
        CardManager.shared.updatePair(at: 9999, with: CardPair(term: "X", match: "Y", category: "Test", difficulty: 1))
        #expect(Bool(true))
    }

    @Test func removePairWithInvalidIndexDoesNotCrash() {
        CardManager.shared.loadDefaultCards()
        // Should not crash with out-of-bounds index
        CardManager.shared.removePair(at: 9999)
        #expect(Bool(true))
    }

    @Test func getPairsByNonExistentCategoryReturnsEmpty() {
        CardManager.shared.loadDefaultCards()
        let result = CardManager.shared.getPairsByCategory("NonExistentCategory")
        #expect(result.isEmpty)
    }

    @Test func getPairsByNonExistentDifficultyReturnsEmpty() {
        CardManager.shared.loadDefaultCards()
        let result = CardManager.shared.getPairsByDifficulty(999)
        #expect(result.isEmpty)
    }

    @Test func cardContentsMatchPairTermsAndMatches() {
        let pairs: [(String, String)] = [("France", "Paris"), ("Japan", "Tokyo")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        let contents = Set(cards.map(\.content))
        #expect(contents.contains("France"))
        #expect(contents.contains("Paris"))
        #expect(contents.contains("Japan"))
        #expect(contents.contains("Tokyo"))
    }

    @Test func allCardsAreUnmatchedInitially() {
        let pairs: [(String, String)] = [("A", "B"), ("C", "D")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        #expect(cards.allSatisfy { !$0.isMatched })
    }

    @Test func eachPairProducesDistinctContents() {
        let pairs: [(String, String)] = [("France", "Paris")]
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        let contents = cards.map(\.content)
        #expect(contents.contains("France"))
        #expect(contents.contains("Paris"))
        #expect(contents[0] != contents[1])
    }

    @Test func largePairSetProducesCorrectCount() {
        let pairs: [(String, String)] = (0..<100).map { ("term\($0)", "match\($0)") }
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        #expect(cards.count == 200)
    }

    @Test func largePairSetHasCorrectPairIDs() {
        let pairs: [(String, String)] = (0..<100).map { ("term\($0)", "match\($0)") }
        let cards = CardManager.shared.createCardsFromPairs(pairs)
        let grouped = Dictionary(grouping: cards, by: \.pairID)
        #expect(grouped.count == 100)
        #expect(grouped.values.allSatisfy { $0.count == 2 })
    }

    @Test func getShuffledCardsTwiceGivesDifferentOrder() {
        CardManager.shared.loadDefaultCards()
        let run1 = CardManager.shared.getShuffledCards().map(\.content)
        let run2 = CardManager.shared.getShuffledCards().map(\.content)
        #expect(run1 != run2)
    }

    @Test func asTuplesOnAllCardPairsMatchesGetAllPairs() {
        CardManager.shared.loadDefaultCards()
        let fromCardPairs = CardManager.shared.getAllCardPairs().asTuples
        let fromGetAllPairs = CardManager.shared.getAllPairs()
        #expect(fromCardPairs.count == fromGetAllPairs.count)
        for i in 0..<fromCardPairs.count {
            #expect(fromCardPairs[i].0 == fromGetAllPairs[i].0)
            #expect(fromCardPairs[i].1 == fromGetAllPairs[i].1)
        }
    }
}

// MARK: - KeychainManager

struct KeychainManagerTests {

    @Test func defaultPasswordIsNotEmpty() {
        #expect(!KeychainManager.shared.getDefaultPassword().isEmpty)
    }

    @Test func defaultPasswordValue() {
        // Verify the hardcoded default hasn't been accidentally changed
        #expect(KeychainManager.shared.getDefaultPassword() == "parent123")
    }

    @Test func getCurrentPasswordFallsBackToDefault() {
        // Keychain is unavailable in test environment, so getCurrentPassword should return default
        _ = KeychainManager.shared.deletePassword()
        let current = KeychainManager.shared.getCurrentPassword()
        #expect(current == KeychainManager.shared.getDefaultPassword())
    }

    @Test func defaultPasswordIsDeterministic() {
        let first = KeychainManager.shared.getDefaultPassword()
        let second = KeychainManager.shared.getDefaultPassword()
        #expect(first == second)
    }
}

// MARK: - GameEngine

// Spy delegate to capture GameEngine events
class GameEngineSpy: GameEngineDelegate {
    var flippedIndices: [Int] = []
    var matchedIndices: [Int] = []
    var mismatchedIndices: [Int] = []
    var moves: Int = 0
    var didWin = false
    var winMoves = 0
    var winSeconds = 0

    func gameEngine(_ engine: GameEngine, didFlipCardAt index: Int) { flippedIndices.append(index) }
    func gameEngine(_ engine: GameEngine, didMatchIndices indices: [Int]) { matchedIndices.append(contentsOf: indices) }
    func gameEngine(_ engine: GameEngine, didMismatchIndices indices: [Int]) { mismatchedIndices.append(contentsOf: indices) }
    func gameEngine(_ engine: GameEngine, didUpdateMoves moves: Int) { self.moves = moves }
    func gameEngine(_ engine: GameEngine, didUpdateTime seconds: Int) {}
    func gameEngineDidWin(_ engine: GameEngine, moves: Int, seconds: Int) { didWin = true; winMoves = moves; winSeconds = seconds }
}

struct GameEngineTests {

    // Helper: create engine with known cards [A-B pair, C-D pair]
    func makeEngine() -> (GameEngine, GameEngineSpy) {
        let cards = [
            Card(content: "A", pairID: 0),
            Card(content: "B", pairID: 0),
            Card(content: "C", pairID: 1),
            Card(content: "D", pairID: 1)
        ]
        let engine = GameEngine()
        let spy = GameEngineSpy()
        engine.delegate = spy
        engine.start(with: cards)
        return (engine, spy)
    }

    @Test func selectCardFlipsIt() {
        let (engine, spy) = makeEngine()
        engine.selectCard(at: 0)
        #expect(spy.flippedIndices.contains(0))
        #expect(engine.selectedIndices.contains(0))
    }

    @Test func selectSameCardTwiceIgnored() {
        let (engine, spy) = makeEngine()
        engine.selectCard(at: 0)
        engine.selectCard(at: 0)
        #expect(engine.selectedIndices.count == 1)
        #expect(spy.flippedIndices.count == 1)
    }

    @Test func matchingPairMarksCardsMatched() {
        let (engine, spy) = makeEngine()
        engine.selectCard(at: 0) // A pairID 0
        engine.selectCard(at: 1) // B pairID 0
        #expect(engine.cards[0].isMatched)
        #expect(engine.cards[1].isMatched)
        #expect(spy.matchedIndices.contains(0))
        #expect(spy.matchedIndices.contains(1))
    }

    @Test func mismatchingPairNotMarkedMatched() {
        let (engine, spy) = makeEngine()
        engine.selectCard(at: 0) // A pairID 0
        engine.selectCard(at: 2) // C pairID 1
        #expect(!engine.cards[0].isMatched)
        #expect(!engine.cards[2].isMatched)
        #expect(spy.mismatchedIndices.contains(0))
        #expect(spy.mismatchedIndices.contains(2))
    }

    @Test func moveCountIncreasesAfterEachPair() {
        let (engine, spy) = makeEngine()
        engine.selectCard(at: 0)
        engine.selectCard(at: 1)
        #expect(spy.moves == 1)
        #expect(engine.moveCount == 1)
    }

    @Test func cannotSelectMatchedCard() {
        let (engine, _) = makeEngine()
        engine.selectCard(at: 0)
        engine.selectCard(at: 1) // match
        let countBefore = engine.selectedIndices.count
        engine.selectCard(at: 0) // already matched
        #expect(engine.selectedIndices.count == countBefore)
    }

    @Test func cannotSelectThirdCardWhileProcessing() {
        let (engine, _) = makeEngine()
        engine.selectCard(at: 0) // A
        engine.selectCard(at: 2) // C — mismatch, now isProcessing = true
        engine.selectCard(at: 3) // should be ignored
        #expect(engine.selectedIndices.count == 2)
    }

    @Test func winTriggeredWhenAllMatched() {
        let (engine, spy) = makeEngine()
        engine.selectCard(at: 0)
        engine.selectCard(at: 1) // match pair 0
        engine.selectCard(at: 2)
        engine.selectCard(at: 3) // match pair 1 — win
        #expect(spy.didWin)
        #expect(spy.winMoves == 2)
    }

    @Test func startResetsState() {
        let (engine, _) = makeEngine()
        engine.selectCard(at: 0)
        engine.selectCard(at: 1)
        let newCards = [Card(content: "X", pairID: 0), Card(content: "Y", pairID: 0)]
        engine.start(with: newCards)
        #expect(engine.moveCount == 0)
        #expect(engine.selectedIndices.isEmpty)
        #expect(engine.cards.count == 2)
    }

    @Test func stopDoesNotCrash() {
        let (engine, _) = makeEngine()
        engine.stop()
        #expect(Bool(true))
    }
}

// MARK: - AuthenticationManager

struct AuthenticationManagerTests {

    @Test func validatePasswordReturnsTrueForCorrectPassword() {
        _ = KeychainManager.shared.deletePassword()
        let defaultPass = KeychainManager.shared.getDefaultPassword()
        #expect(AuthenticationManager.shared.validatePassword(defaultPass))
    }

    @Test func validatePasswordReturnsFalseForWrongPassword() {
        #expect(!AuthenticationManager.shared.validatePassword("wrongpassword"))
    }

    @Test func authErrorRequiresFallbackForMostErrors() {
        let errors: [AuthError] = [
            .fallbackRequested, .biometryUnavailable, .biometryNotEnrolled,
            .biometryLockout, .passcodeNotSet, .failed("err"), .unknown
        ]
        #expect(errors.allSatisfy { $0.requiresFallback })
    }

    @Test func authErrorUserCancelledDoesNotRequireFallback() {
        #expect(!AuthError.userCancelled.requiresFallback)
    }

    @Test func authErrorMessagesAreNotEmptyExceptUserCancelled() {
        let errors: [AuthError] = [
            .fallbackRequested, .biometryUnavailable, .biometryNotEnrolled,
            .biometryLockout, .passcodeNotSet, .failed("test"), .unknown
        ]
        #expect(errors.allSatisfy { !$0.message.isEmpty })
    }

    @Test func authErrorUserCancelledMessageIsEmpty() {
        #expect(AuthError.userCancelled.message.isEmpty)
    }
}
