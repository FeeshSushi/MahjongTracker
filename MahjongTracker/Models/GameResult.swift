import Foundation

struct GameResult: Codable, Identifiable {
    var id: UUID = UUID()
    var datePlayed: Date = Date()
    var finalPoints: Int
    var placement: Int  // 1, 2, 3, or 4
}
