import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var colorHex: String = "#5E8CF0"
    var createdAt: Date = Date()
    var gameResultsJSON: Data = Data()

    var gameResults: [GameResult] {
        get { (try? JSONDecoder().decode([GameResult].self, from: gameResultsJSON)) ?? [] }
        set { gameResultsJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(name: String, emoji: String, colorHex: String = "#5E8CF0") {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
    }
}
