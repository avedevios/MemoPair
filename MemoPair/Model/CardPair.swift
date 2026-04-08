import Foundation

struct CardPair: Codable {
    let term: String
    let match: String
    let category: String
    let difficulty: Int
    
    // Вычисляемое свойство для совместимости с существующим кодом
    var tuple: (String, String) {
        return (term, match)
    }
}

// Расширение для совместимости с существующим кодом
extension Array where Element == CardPair {
    var asTuples: [(String, String)] {
        return self.map { $0.tuple }
    }
}
