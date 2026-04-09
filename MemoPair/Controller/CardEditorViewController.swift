//
//  CardEditorViewController.swift
//  MemoPair
//
import UIKit

protocol CardEditorDelegate: AnyObject {
    func didUpdateCards()
}

class CardEditorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: CardEditorDelegate?

    let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // Computed — always in sync with CardManager, no local cache
    private var pairs: [CardPair] { CardManager.shared.getAllCardPairs() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Cards"
        view.backgroundColor = .systemBackground

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.didUpdateCards()
    }

    // MARK: - Actions

    @objc func addNewCard() {
        showEditor(for: nil)
    }

    @objc func showSettings() {
        let preferredStyle: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
        let alert = UIAlertController(title: "Settings", message: "Choose an option", preferredStyle: preferredStyle)

        alert.addAction(UIAlertAction(title: "Change Password", style: .default) { [weak self] _ in
            self?.showPasswordChangeAlert()
        })
        alert.addAction(UIAlertAction(title: "Reset to Default Cards", style: .destructive) { [weak self] _ in
            self?.showResetConfirmation()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if preferredStyle == .actionSheet, let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
            if popover.barButtonItem == nil {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }

        present(alert, animated: true)
    }

    // MARK: - Editor

    func showEditor(for index: Int?) {
        let alert = UIAlertController(title: index == nil ? "New Card" : "Edit Card", message: nil, preferredStyle: .alert)

        alert.addTextField {
            $0.placeholder = "Term"
            if let index = index { $0.text = self.pairs[index].term }
        }
        alert.addTextField {
            $0.placeholder = "Match"
            if let index = index { $0.text = self.pairs[index].match }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let term = alert.textFields?[0].text, !term.isEmpty,
                  let match = alert.textFields?[1].text, !match.isEmpty else { return }

            if let index = index {
                CardManager.shared.updatePair(at: index, with: CardPair(term: term, match: match, category: "Custom", difficulty: 1))
            } else {
                let isDuplicate = self.pairs.contains {
                    $0.term.lowercased() == term.lowercased() || $0.match.lowercased() == match.lowercased()
                }
                guard !isDuplicate else {
                    let err = UIAlertController(title: "Duplicate", message: "A card with this term or match already exists.", preferredStyle: .alert)
                    err.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.present(err, animated: true)
                    return
                }
                CardManager.shared.addPair(CardPair(term: term, match: match, category: "Custom", difficulty: 1))
            }
            self.tableView.reloadData()
        })

        present(alert, animated: true)
    }

    // MARK: - Settings helpers

    private func showPasswordChangeAlert() {
        let alert = UIAlertController(title: "Change Password", message: "Enter password details", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Current Password"; $0.isSecureTextEntry = true }
        alert.addTextField { $0.placeholder = "New Password"; $0.isSecureTextEntry = true }
        alert.addTextField { $0.placeholder = "Confirm New Password"; $0.isSecureTextEntry = true }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Change Password", style: .default) { [weak self] _ in
            guard let self = self,
                  let current = alert.textFields?[0].text, !current.isEmpty,
                  let new = alert.textFields?[1].text, !new.isEmpty,
                  let confirm = alert.textFields?[2].text, !confirm.isEmpty else { return }

            guard AuthenticationManager.shared.validatePassword(current) else {
                self.showError("Current password is incorrect.")
                return
            }
            guard new == confirm else {
                self.showError("New passwords do not match.")
                return
            }
            if KeychainManager.shared.savePassword(new) {
                self.showInfo(title: "Success", message: "Password changed successfully.")
            } else {
                self.showError("Failed to save password to Keychain.")
            }
        })
        present(alert, animated: true)
    }

    private func showResetConfirmation() {
        let alert = UIAlertController(title: "Reset to Default", message: "This will remove all custom cards and restore the original set. Are you sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            CardManager.shared.resetToDefault()
            self?.tableView.reloadData()
            self?.showInfo(title: "Reset Complete", message: "Cards have been reset to default values.")
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showInfo(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pairs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let pair = pairs[indexPath.row]
        cell.textLabel?.text = pair.term
        cell.detailTextLabel?.text = pair.match
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEditor(for: indexPath.row)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        CardManager.shared.removePair(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
