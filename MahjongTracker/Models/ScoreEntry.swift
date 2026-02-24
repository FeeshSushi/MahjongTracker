import Foundation

enum WinType: String, Codable {
    case tsumo
    case dealIn
    case manual
}

struct ScoreEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var prevailingWind: Wind
    var dealerSeatIndex: Int
    var honba: Int
    var winType: WinType
    var winnerIndex: Int    // -1 for manual entries
    var discarderIndex: Int? // nil for tsumo and manual
    var fan: Int
    var deltas: [Int]        // length 4, positive = gained, negative = paid
    var summary: String
}
