import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var colorHex: String = "#5E8CF0"
    var createdAt: Date = Date()

    init(name: String, emoji: String, colorHex: String = "#5E8CF0") {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
    }
}
