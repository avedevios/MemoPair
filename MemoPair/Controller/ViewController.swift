import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    
    var collectionView: UICollectionView!
    var cards = [Card]()
    var selectedIndices: [IndexPath] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let parentButton = UIBarButtonItem(title: "Parent Mode", style: .plain, target: self, action: #selector(authenticateParent))
        navigationItem.rightBarButtonItem = parentButton
        
        setupCards()
        setupCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let spacing: CGFloat = layout.minimumInteritemSpacing
        let lines: CGFloat = 4
        let columns: CGFloat = 4

        let totalSpacingX = spacing * (columns + 1)
        let totalSpacingY = spacing * (lines + 1)

        let availableWidth = collectionView.bounds.width - totalSpacingX
        let availableHeight = collectionView.bounds.height - totalSpacingY

        let itemWidth = floor(availableWidth / columns)
        let itemHeight = floor(availableHeight / lines)

        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    }
    
    func setupCards() {
        cards = CardManager.shared.getShuffledCards()
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.register(CardCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
        collectionView.delegate = self

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    func checkMatch() {
        guard selectedIndices.count == 2 else { return }
        let first = cards[selectedIndices[0].item]
        let second = cards[selectedIndices[1].item]
        
        if first.pairID == second.pairID {
            cards[selectedIndices[0].item].isMatched = true
            cards[selectedIndices[1].item].isMatched = true
            selectedIndices.removeAll()
            checkWin()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let firstCell = self.collectionView.cellForItem(at: self.selectedIndices[0]) as? CardCell {
                    firstCell.configure(with: nil, isFaceUp: false, animated: true)
                }
                if let secondCell = self.collectionView.cellForItem(at: self.selectedIndices[1]) as? CardCell {
                    secondCell.configure(with: nil, isFaceUp: false, animated: true)
                }
                
                self.selectedIndices.removeAll()
                //self.collectionView.reloadData()
            }
        }
    }
    
    func checkWin() {
        if cards.allSatisfy({ $0.isMatched }) {
            let alert = UIAlertController(title: "You Win!", message: "All pairs matched!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Play Again", style: .default) { _ in
                self.setupCards()
                self.collectionView.reloadData()
            })
            present(alert, animated: true)
        }
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
        cell.configure(with: card.content, isFaceUp: isFaceUp, animated: true)
        
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
        let editorVC = CardEditorViewController()
        editorVC.delegate = self
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    @objc func authenticateParent() {
        // Создаем контекст для биометрической аутентификации
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Access Parental Controls") { [weak self] success, authError in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if success {
                        self.showCardEditor()
                    } else {
                        var message = "You could not be verified."
                        var showFallbackOption = false
                        
                        if let authError = authError {
                            if let laError = authError as? LAError {
                                switch laError.code {
                                case .userCancel:
                                    message = "Authentication was cancelled."
                                    return // Не показываем алерт при отмене
                                case .userFallback:
                                    message = "User chose to use fallback authentication."
                                    showFallbackOption = true
                                case .biometryNotAvailable:
                                    message = "Biometric authentication is not available."
                                    showFallbackOption = true
                                case .biometryNotEnrolled:
                                    message = "No biometric authentication is enrolled."
                                    showFallbackOption = true
                                case .biometryLockout:
                                    message = "Biometric authentication is locked out."
                                    showFallbackOption = true
                                default:
                                    message = "Authentication failed with error: \(authError.localizedDescription)"
                                    showFallbackOption = true
                                }
                            } else {
                                message = "Authentication failed with error: \(authError.localizedDescription)"
                                showFallbackOption = true
                            }
                        }
                        
                        let alert = UIAlertController(title: "Authentication Failed", message: message, preferredStyle: .alert)
                        
                        if showFallbackOption {
                            alert.addAction(UIAlertAction(title: "Use Password", style: .default) { [weak self] _ in
                                self?.showPasswordAuthentication()
                            })
                        }
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        self.present(alert, animated: true)
                    }
                }
            }
        } else {
            var message = "Biometric authentication not available."
            if let error = error {
                switch error.code {
                case LAError.biometryNotEnrolled.rawValue:
                    message = "No biometric authentication is enrolled on this device."
                case LAError.biometryNotAvailable.rawValue:
                    message = "Biometric authentication is not available on this device."
                case LAError.passcodeNotSet.rawValue:
                    message = "Passcode is not set on this device."
                default:
                    message = "Biometric authentication error: \(error.localizedDescription)"
                }
            }
            
            let alert = UIAlertController(title: "Unavailable", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Use Password", style: .default) { [weak self] _ in
                self?.showPasswordAuthentication()
            })
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
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
            
            // Проверяем пароль из Keychain или используем пароль по умолчанию
            let savedPassword = KeychainManager.shared.getCurrentPassword()
            
            if password == savedPassword {
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
        setupCards() // Загружает базовые и кастомные пары
        collectionView.reloadData() // Обновляет отображение
    }
}

// MARK: - Card Cell

class CardCell: UICollectionViewCell {
    
    let label = UILabel()
    let backgroundImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.numberOfLines = 0
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.9)
        ])
    }

    func configure(with text: String?, isFaceUp: Bool, animated: Bool = false) {
        
        let options: UIView.AnimationOptions = isFaceUp ? .transitionFlipFromLeft : .transitionFlipFromRight
        
        if animated {
            UIView.transition(with: contentView, duration: 0.3, options: [options, .showHideTransitionViews], animations: {
                self.updateAppearance(text: text, isFaceUp: isFaceUp)
            }, completion: nil)
        } else {
            updateAppearance(text: text, isFaceUp: isFaceUp)
        }
    }
    
    private func updateAppearance(text: String?, isFaceUp: Bool) {
        if isFaceUp {
            backgroundImageView.image = nil
            contentView.backgroundColor = .systemTeal
            label.text = text
        } else {
            backgroundImageView.image = UIImage(named: "rubashka")
            contentView.backgroundColor = .clear
            label.text = ""
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

