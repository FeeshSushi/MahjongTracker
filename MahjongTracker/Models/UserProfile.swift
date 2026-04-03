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

    @Relationship(deleteRule: .cascade) var gameResults: [GameResultRecord] = []

    init(name: String, emoji: String, colorHex: String = "#5E8CF0") {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
    }
}
