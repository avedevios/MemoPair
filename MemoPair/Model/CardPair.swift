import Foundation

struct CardPair: Codable {
    let term: String
    let match: String
    let category: String
    let difficulty: Int
    
    // Computed property for compatibility with existing code
    var tuple: (String, String) {
        return (term, match)
    }
}

// Extension for compatibility with existing code
extension Array where Element == CardPair {
    var asTuples: [(String, String)] {
        return self.map { $0.tuple }
    }
}
