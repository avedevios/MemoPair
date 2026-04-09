import UIKit
import AudioToolbox

class ViewController: UIViewController {
    
    var collectionView: UICollectionView!
    var cards = [Card]()
    var selectedIndices: [IndexPath] = []
    var moveCount = 0
    let movesLabel = UILabel()
    var timer: Timer?
    var elapsedSeconds = 0
    let timerLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let parentButton = UIBarButtonItem(title: "Parent Mode", style: .plain, target: self, action: #selector(authenticateParent))
        navigationItem.rightBarButtonItem = parentButton
        
        setupMovesLabel()
        setupTimerLabel()
        setupCards()
        setupCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let spacing: CGFloat = layout.minimumInteritemSpacing
        let count = cards.count
        guard count > 0 else { return }

        // Find the most square grid layout for the card count
        let columns = CGFloat(optimalColumns(for: count))
        let lines = CGFloat(ceil(Double(count) / Double(Int(columns))))

        let totalSpacingX = spacing * (columns + 1)
        let totalSpacingY = spacing * (lines + 1)

        let availableWidth = collectionView.bounds.width - totalSpacingX
        let availableHeight = collectionView.bounds.height - totalSpacingY

        let itemWidth = floor(availableWidth / columns)
        let itemHeight = floor(availableHeight / lines)

        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    }

    private func optimalColumns(for count: Int) -> Int {
        // Find column count that produces the most square grid
        let sqrt = Int(Double(count).squareRoot())
        for cols in stride(from: sqrt + 1, through: 2, by: -1) {
            if count % cols == 0 { return cols }
        }
        return max(2, sqrt)
    }
    
    func setupCards() {
        cards = CardManager.shared.getShuffledCards()
        moveCount = 0
        movesLabel.text = "Moves: 0"
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        elapsedSeconds = 0
        timerLabel.text = "Time: 0:00"
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            let minutes = self.elapsedSeconds / 60
            let seconds = self.elapsedSeconds % 60
            self.timerLabel.text = String(format: "Time: %d:%02d", minutes, seconds)
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func setupTimerLabel() {
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        timerLabel.textColor = .secondaryLabel
        view.addSubview(timerLabel)
        
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    func setupMovesLabel() {
        movesLabel.translatesAutoresizingMaskIntoConstraints = false
        movesLabel.textAlignment = .center
        movesLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        movesLabel.textColor = .secondaryLabel
        view.addSubview(movesLabel)
        
        NSLayoutConstraint.activate([
            movesLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            movesLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
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
    
    func checkMatch() {
        guard selectedIndices.count == 2 else { return }
        let first = cards[selectedIndices[0].item]
        let second = cards[selectedIndices[1].item]
        
        moveCount += 1
        movesLabel.text = "Moves: \(moveCount)"
        
        if first.pairID == second.pairID {
            cards[selectedIndices[0].item].isMatched = true
            cards[selectedIndices[1].item].isMatched = true
            // Reload to show matched (green) state
            let matched = selectedIndices
            selectedIndices.removeAll()
            collectionView.reloadItems(at: matched)
            AudioServicesPlaySystemSound(1025) // match sound
            checkWin()
        } else {
            AudioServicesPlaySystemSound(1057) // subtle tap for no match
            // Shake both cells
            if let firstCell = collectionView.cellForItem(at: selectedIndices[0]) as? CardCell {
                firstCell.shake()
            }
            if let secondCell = collectionView.cellForItem(at: selectedIndices[1]) as? CardCell {
                secondCell.shake()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let firstCell = self.collectionView.cellForItem(at: self.selectedIndices[0]) as? CardCell {
                    firstCell.configure(with: nil, isFaceUp: false, animated: true)
                }
                if let secondCell = self.collectionView.cellForItem(at: self.selectedIndices[1]) as? CardCell {
                    secondCell.configure(with: nil, isFaceUp: false, animated: true)
                }
                self.selectedIndices.removeAll()
            }
        }
    }
    
    func checkWin() {
        if cards.allSatisfy({ $0.isMatched }) {
            stopTimer()
            showConfetti()
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            let timeStr = String(format: "%d:%02d", minutes, seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = UIAlertController(title: "You Win! 🎉", message: "Moves: \(self.moveCount)  Time: \(timeStr)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Play Again", style: .default) { _ in
                    self.stopConfetti()
                    self.setupCards()
                    self.collectionView.reloadData()
                })
                self.present(alert, animated: true)
            }
        }
    }
    
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitter.birthRate = 0
        }
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
}

// MARK: - CollectionView

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card = cards[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CardCell
        
        let isFaceUp = selectedIndices.contains(indexPath) || card.isMatched
        cell.configure(with: card.content, isFaceUp: isFaceUp, pairID: card.pairID, isMatched: card.isMatched, animated: false)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectedIndices.count < 2,
              !cards[indexPath.item].isMatched,
              !selectedIndices.contains(indexPath) else { return }

        selectedIndices.append(indexPath)
        collectionView.reloadItems(at: [indexPath])
        
        if selectedIndices.count == 2 {
            checkMatch()
        }
    }
    
    func showCardEditor() {
        stopTimer()
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
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            guard let self = self,
                  let password = alert.textFields?.first?.text,
                  !password.isEmpty else { return }
            
            if AuthenticationManager.shared.validatePassword(password) {
                self.showCardEditor()
            } else {
                let errorAlert = UIAlertController(title: "Incorrect Password", message: "The password you entered is incorrect.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(errorAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    

}

extension ViewController: CardEditorDelegate {
    func didUpdateCards() {
        setupCards() // Load base and custom pairs
        collectionView.reloadData() // Refresh display
    }
}

