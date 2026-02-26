import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MahjongTracker", category: "UserProfile")

@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var colorHex: String = "#5E8CF0"
    var createdAt: Date = Date()
    var gameResultsJSON: Data = Data()

    var gameResults: [GameResult] {
        get {
            do { return try JSONDecoder().decode([GameResult].self, from: gameResultsJSON) }
            catch { logger.error("Failed to decode gameResults: \(error)"); return [] }
        }
        set {
            do { gameResultsJSON = try JSONEncoder().encode(newValue) }
            catch { logger.error("Failed to encode gameResults: \(error)") }
        }
    }

    init(name: String, emoji: String, colorHex: String = "#5E8CF0") {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
    }
}
