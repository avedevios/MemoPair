import UIKit

protocol CardEditorDelegate: AnyObject {
    func didUpdateCards()
}

class CardEditorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: CardEditorDelegate?

    var customPairs: [(String, String)] = []

    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Cards"
        view.backgroundColor = .systemBackground

        loadCustomPairs()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewCard))
        let settingsButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
        navigationItem.rightBarButtonItems = [addButton, settingsButton]
    }

    func loadCustomPairs() {
        // Load all pairs from CardManager
        customPairs = CardManager.shared.getAllPairs()
    }



    @objc func addNewCard() {
        showEditor(for: nil)
    }
    

    
    @objc func showSettings() {
        // On iPad use regular Alert, on iPhone use ActionSheet
        let preferredStyle: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
        
        let alert = UIAlertController(title: "Settings", message: "Choose an option", preferredStyle: preferredStyle)
        
        // Change password button
        alert.addAction(UIAlertAction(title: "Change Password", style: .default) { [weak self] _ in
            self?.showPasswordChangeAlert()
        })
        
        // Reset to default cards button
        alert.addAction(UIAlertAction(title: "Reset to Default Cards", style: .destructive) { [weak self] _ in
            self?.showResetConfirmation()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // No popover needed for regular Alert on iPad
        if preferredStyle == .actionSheet {
            if let popover = alert.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?.last
                if popover.barButtonItem == nil {
                    popover.sourceView = view
                    popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                }
            }
        }
        
        present(alert, animated: true)
    }
    
    private func showPasswordChangeAlert() {
        let alert = UIAlertController(title: "Change Password", message: "Enter password details", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Current Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "New Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Confirm New Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Change Password", style: .default) { [weak self] _ in
            guard let self = self,
                  let currentPassword = alert.textFields?[0].text,
                  let newPassword = alert.textFields?[1].text,
                  let confirmPassword = alert.textFields?[2].text,
                  !currentPassword.isEmpty,
                  !newPassword.isEmpty,
                  !confirmPassword.isEmpty else { return }
            
            // Verify current password from Keychain
            guard AuthenticationManager.shared.validatePassword(currentPassword) else {
                let errorAlert = UIAlertController(title: "Error", message: "Current password is incorrect.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(errorAlert, animated: true)
                return
            }
            
            // Verify new password matches confirmation
            guard newPassword == confirmPassword else {
                let errorAlert = UIAlertController(title: "Error", message: "New passwords do not match.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(errorAlert, animated: true)
                return
            }
            
            // Save new password to Keychain
            if KeychainManager.shared.savePassword(newPassword) {
                let successAlert = UIAlertController(title: "Success", message: "Password changed successfully.", preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(successAlert, animated: true)
            } else {
                let errorAlert = UIAlertController(title: "Error", message: "Failed to save password to Keychain", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(errorAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showResetConfirmation() {
        let alert = UIAlertController(
            title: "Reset to Default",
            message: "This will remove all custom cards and restore the original set. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            // Reset to default cards
            CardManager.shared.resetToDefault()
            
            // Reload data
            self?.loadCustomPairs()
            self?.tableView.reloadData()
            
            // Show confirmation
            let successAlert = UIAlertController(
                title: "Reset Complete",
                message: "Cards have been reset to default values.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self?.present(successAlert, animated: true)
        })
        
        present(alert, animated: true)
    }

    func showEditor(for index: Int?) {
        let alert = UIAlertController(title: index == nil ? "New Card" : "Edit Card", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Term"
            if let index = index {
                textField.text = self.customPairs[index].0
            }
        }

        alert.addTextField { textField in
            textField.placeholder = "Match"
            if let index = index {
                textField.text = self.customPairs[index].1
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            guard let term = alert.textFields?[0].text, !term.isEmpty,
                  let match = alert.textFields?[1].text, !match.isEmpty else { return }

            if let index = index {
                // Update existing pair via CardManager
                let updatedPair = CardPair(term: term, match: match, category: "Custom", difficulty: 1)
                CardManager.shared.updatePair(at: index, with: updatedPair)
            } else {
                // Check for duplicates before adding
                let isDuplicate = CardManager.shared.getAllCardPairs().contains {
                    $0.term.lowercased() == term.lowercased() || $0.match.lowercased() == match.lowercased()
                }
                if isDuplicate {
                    let errorAlert = UIAlertController(title: "Duplicate", message: "A card with this term or match already exists.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.present(errorAlert, animated: true)
                    return
                }
                // Add new pair via CardManager
                let newPair = CardPair(term: term, match: match, category: "Custom", difficulty: 1)
                CardManager.shared.addPair(newPair)
            }

            self.loadCustomPairs() // Reload data
            self.tableView.reloadData()
        }))

        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customPairs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let pair = customPairs[indexPath.row]
        cell.textLabel?.text = pair.0
        cell.detailTextLabel?.text = pair.1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEditor(for: indexPath.row)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            CardManager.shared.removePair(at: indexPath.row)
            loadCustomPairs() // Reload data
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.didUpdateCards()
    }
}
