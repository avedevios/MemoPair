//
//  ViewController.swift
//  MemoPair
//
import UIKit
import AudioToolbox

class ViewController: UIViewController {

    // MARK: - Properties

    var collectionView: UICollectionView!
    let movesLabel = UILabel()
    let timerLabel = UILabel()

    private let engine = GameEngine()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let parentButton = UIBarButtonItem(title: "Parent Mode", style: .plain, target: self, action: #selector(authenticateParent))
        navigationItem.rightBarButtonItem = parentButton

        engine.delegate = self
        setupMovesLabel()
        setupTimerLabel()
        setupCollectionView()
        startNewGame()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let count = engine.cards.count
        guard count > 0 else { return }

        let spacing: CGFloat = layout.minimumInteritemSpacing
        let columns = CGFloat(optimalColumns(for: count))
        let lines = CGFloat(ceil(Double(count) / Double(Int(columns))))

        let availableWidth = collectionView.bounds.width - spacing * (columns + 1)
        let availableHeight = collectionView.bounds.height - spacing * (lines + 1)

        layout.itemSize = CGSize(width: floor(availableWidth / columns),
                                 height: floor(availableHeight / lines))
    }

    // MARK: - Setup

    func setupMovesLabel() {
        movesLabel.translatesAutoresizingMaskIntoConstraints = false
        movesLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        movesLabel.textColor = .secondaryLabel
        movesLabel.text = "Moves: 0"
        view.addSubview(movesLabel)
        NSLayoutConstraint.activate([
            movesLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            movesLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
    }

    func setupTimerLabel() {
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        timerLabel.textColor = .secondaryLabel
        timerLabel.text = "Time: 0:00"
        view.addSubview(timerLabel)
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.register(CardCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: movesLabel.bottomAnchor, constant: 8),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Game

    func startNewGame() {
        engine.start(with: CardManager.shared.getShuffledCards())
        movesLabel.text = "Moves: 0"
        timerLabel.text = "Time: 0:00"
        collectionView.reloadData()
    }

    private func optimalColumns(for count: Int) -> Int {
        let sqrt = Int(Double(count).squareRoot())
        for cols in stride(from: sqrt + 1, through: 2, by: -1) {
            if count % cols == 0 { return cols }
        }
        return max(2, sqrt)
    }

    // MARK: - Confetti

    func showConfetti() {
        let emitter = CAEmitterLayer()
        emitter.name = "confettiEmitter"
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)

        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple, .systemOrange]
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 4
            cell.velocity = 200
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 3
            cell.scaleRange = 0.3
            cell.scale = 0.5
            cell.color = color.cgColor
            cell.contents = makeConfettiImage()
            return cell
        }
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { emitter.birthRate = 0 }
    }

    func stopConfetti() {
        view.layer.sublayers?.filter { $0.name == "confettiEmitter" }.forEach { $0.removeFromSuperlayer() }
    }

    private func makeConfettiImage() -> CGImage? {
        let size = CGSize(width: 10, height: 6)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.cgImage
    }

    // MARK: - Parent Mode

    func showCardEditor() {
        engine.stop()
        let editorVC = CardEditorViewController()
        editorVC.delegate = self
        navigationController?.pushViewController(editorVC, animated: true)
    }

    @objc func authenticateParent() {
        AuthenticationManager.shared.authenticateWithBiometrics(reason: "Access Parental Controls") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.showCardEditor()
            case .failure(let error):
                guard error.requiresFallback else { return }
                let alert = UIAlertController(title: "Authentication Failed", message: error.message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Use Password", style: .default) { [weak self] _ in
                    self?.showPasswordAuthentication()
                })
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }

    func showPasswordAuthentication() {
        let alert = UIAlertController(title: "Enter Password", message: "Please enter the parent password to continue", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Password"; $0.isSecureTextEntry = true }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            guard let self = self,
                  let password = alert.textFields?.first?.text,
                  !password.isEmpty else { return }
            if AuthenticationManager.shared.validatePassword(password) {
                self.showCardEditor()
            } else {
                let err = UIAlertController(title: "Incorrect Password", message: "The password you entered is incorrect.", preferredStyle: .alert)
                err.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(err, animated: true)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - GameEngineDelegate

extension ViewController: GameEngineDelegate {

    func gameEngine(_ engine: GameEngine, didFlipCardAt index: Int) {
        collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
    }

    func gameEngine(_ engine: GameEngine, didMatchIndices indices: [Int]) {
        AudioServicesPlaySystemSound(1025)
        collectionView.reloadItems(at: indices.map { IndexPath(item: $0, section: 0) })
    }

    func gameEngine(_ engine: GameEngine, didMismatchIndices indices: [Int]) {
        AudioServicesPlaySystemSound(1057)
        let indexPaths = indices.map { IndexPath(item: $0, section: 0) }
        indexPaths.forEach { ip in
            (collectionView.cellForItem(at: ip) as? CardCell)?.shake()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            indexPaths.forEach { ip in
                (self.collectionView.cellForItem(at: ip) as? CardCell)?
                    .configure(with: nil, isFaceUp: false, animated: true)
            }
        }
    }

    func gameEngine(_ engine: GameEngine, didUpdateMoves moves: Int) {
        movesLabel.text = "Moves: \(moves)"
    }

    func gameEngine(_ engine: GameEngine, didUpdateTime seconds: Int) {
        let m = seconds / 60, s = seconds % 60
        timerLabel.text = String(format: "Time: %d:%02d", m, s)
    }

    func gameEngineDidWin(_ engine: GameEngine, moves: Int, seconds: Int) {
        showConfetti()
        let timeStr = String(format: "%d:%02d", seconds / 60, seconds % 60)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = UIAlertController(title: "You Win! 🎉", message: "Moves: \(moves)  Time: \(timeStr)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Play Again", style: .default) { _ in
                self.stopConfetti()
                self.startNewGame()
            })
            self.present(alert, animated: true)
        }
    }
}

// MARK: - CollectionView

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        engine.cards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card = engine.cards[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CardCell
        let isFaceUp = engine.selectedIndices.contains(indexPath.item) || card.isMatched
        cell.configure(with: card.content, isFaceUp: isFaceUp, pairID: card.pairID, isMatched: card.isMatched, animated: false)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        engine.selectCard(at: indexPath.item)
    }
}

// MARK: - CardEditorDelegate

extension ViewController: CardEditorDelegate {
    func didUpdateCards() {
        startNewGame()
    }
}
