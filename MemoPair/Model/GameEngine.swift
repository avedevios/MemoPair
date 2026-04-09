//
//  GameEngine.swift
//  MemoPair
//
import Foundation

protocol GameEngineDelegate: AnyObject {
    func gameEngine(_ engine: GameEngine, didFlipCardAt index: Int)
    func gameEngine(_ engine: GameEngine, didMatchIndices indices: [Int])
    func gameEngine(_ engine: GameEngine, didMismatchIndices indices: [Int])
    func gameEngine(_ engine: GameEngine, didUpdateMoves moves: Int)
    func gameEngine(_ engine: GameEngine, didUpdateTime seconds: Int)
    func gameEngineDidWin(_ engine: GameEngine, moves: Int, seconds: Int)
}

class GameEngine {

    // MARK: - Properties

    weak var delegate: GameEngineDelegate?

    private(set) var cards: [Card] = []
    private(set) var selectedIndices: [Int] = []
    private(set) var moveCount = 0
    private(set) var elapsedSeconds = 0
    private var isProcessing = false

    private var timer: Timer?

    // MARK: - Game lifecycle

    func start(with cards: [Card]) {
        self.cards = cards
        selectedIndices = []
        moveCount = 0
        elapsedSeconds = 0
        isProcessing = false
        startTimer()
    }

    func stop() {
        stopTimer()
    }

    // MARK: - Card selection

    func selectCard(at index: Int) {
        guard !isProcessing,
              index < cards.count,
              !cards[index].isMatched,
              !selectedIndices.contains(index),
              selectedIndices.count < 2 else { return }

        selectedIndices.append(index)
        delegate?.gameEngine(self, didFlipCardAt: index)

        if selectedIndices.count == 2 {
            checkMatch()
        }
    }

    // MARK: - Private

    private func checkMatch() {
        let first = cards[selectedIndices[0]]
        let second = cards[selectedIndices[1]]

        moveCount += 1
        delegate?.gameEngine(self, didUpdateMoves: moveCount)

        if first.pairID == second.pairID {
            cards[selectedIndices[0]].isMatched = true
            cards[selectedIndices[1]].isMatched = true
            let matched = selectedIndices
            selectedIndices = []
            delegate?.gameEngine(self, didMatchIndices: matched)

            if cards.allSatisfy({ $0.isMatched }) {
                stopTimer()
                delegate?.gameEngineDidWin(self, moves: moveCount, seconds: elapsedSeconds)
            }
        } else {
            isProcessing = true
            let mismatched = selectedIndices
            delegate?.gameEngine(self, didMismatchIndices: mismatched)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.selectedIndices = []
                self.isProcessing = false
            }
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.delegate?.gameEngine(self, didUpdateTime: self.elapsedSeconds)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
