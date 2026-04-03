import Foundation
import SwiftData

@Model
final class PlayerRecord {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var colorHex: String = ""
    var points: Int = 0
    var seatIndex: Int = 0  // stable seat identity (0–3), updated during intro shuffle

    init(name: String, emoji: String, colorHex: String, points: Int, seatIndex: Int) {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.points = points
        self.seatIndex = seatIndex
    }
}
