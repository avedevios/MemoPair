import Foundation

class CardManager {
    static let shared = CardManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private var allCardPairs: [CardPair] = []
    private var defaultCardPairs: [CardPair] = []
    
    // MARK: - Initialization
    
    func loadDefaultCards() {
        // Load base cards
        loadBaseCards()
        
        // Load saved cards or fall back to defaults
        if let savedPairs = loadSavedPairs() {
            allCardPairs = savedPairs
        } else {
            allCardPairs = defaultCardPairs
        }
    }
    
    private func loadBaseCards() {
        guard let url = Bundle.main.url(forResource: "DefaultCards", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let pairs = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]] else {
            // Fallback to hardcoded cards if plist is not found
            loadFallbackCards()
            return
        }
        
        defaultCardPairs = pairs.compactMap { dict in
            guard let term = dict["term"] as? String,
                  let match = dict["match"] as? String,
                  let category = dict["category"] as? String,
                  let difficulty = dict["difficulty"] as? Int else {
                return nil
            }
            return CardPair(term: term, match: match, category: category, difficulty: difficulty)
        }
    }
    
    private func loadFallbackCards() {
        // Fallback data in case plist is not found
        defaultCardPairs = [
            CardPair(term: "France", match: "Paris", category: "Geography", difficulty: 1),
            CardPair(term: "Japan", match: "Tokyo", category: "Geography", difficulty: 1),
            CardPair(term: "Italy", match: "Rome", category: "Geography", difficulty: 1),
            CardPair(term: "Germany", match: "Berlin", category: "Geography", difficulty: 1),
            CardPair(term: "Canada", match: "Ottawa", category: "Geography", difficulty: 1),
            CardPair(term: "Brazil", match: "Brasília", category: "Geography", difficulty: 1),
            CardPair(term: "Australia", match: "Canberra", category: "Geography", difficulty: 1),
            CardPair(term: "India", match: "New Delhi", category: "Geography", difficulty: 1)
        ]
    }
    
    // MARK: - Public Methods
    
    func getAllPairs() -> [(String, String)] {
        return allCardPairs.asTuples
    }
    
    func getAllCardPairs() -> [CardPair] {
        return allCardPairs
    }
    
    func getPairsByCategory(_ category: String) -> [CardPair] {
        return allCardPairs.filter { $0.category == category }
    }
    
    func getPairsByDifficulty(_ difficulty: Int) -> [CardPair] {
        return allCardPairs.filter { $0.difficulty == difficulty }
    }
    
    func addPair(_ pair: CardPair) {
        allCardPairs.append(pair)
        savePairs()
    }
    
    func updatePair(at index: Int, with pair: CardPair) {
        guard index < allCardPairs.count else { return }
        allCardPairs[index] = pair
        savePairs()
    }
    
    func removePair(at index: Int) {
        guard index < allCardPairs.count else { return }
        allCardPairs.remove(at: index)
        savePairs()
    }
    
    func resetToDefault() {
        allCardPairs = defaultCardPairs
        savePairs()
    }
    
    func createCardsFromPairs(_ pairs: [(String, String)]) -> [Card] {
        var tempCards = [Card]()
        for (i, pair) in pairs.enumerated() {
            tempCards.append(Card(content: pair.0, pairID: i))
            tempCards.append(Card(content: pair.1, pairID: i))
        }
        return tempCards.shuffled()
    }
    
    func getShuffledCards() -> [Card] {
        let pairs = getAllPairs()
        return createCardsFromPairs(pairs)
    }
    
    // MARK: - Private Methods
    
    private func savePairs() {
        guard let data = try? JSONEncoder().encode(allCardPairs) else { return }
        UserDefaults.standard.set(data, forKey: "allPairs")
    }
    
    private func loadSavedPairs() -> [CardPair]? {
        guard let data = UserDefaults.standard.data(forKey: "allPairs"),
              let pairs = try? JSONDecoder().decode([CardPair].self, from: data) else { return nil }
        return pairs
    }
}
