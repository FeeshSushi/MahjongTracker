import Foundation

struct PlayerState: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var emoji: String = ""
    var colorHex: String = ""
    var points: Int
}
