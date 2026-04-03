import Foundation
import SwiftData

@Model
final class GameResultRecord {
    var id: UUID = UUID()
    var datePlayed: Date = Date()
    var finalPoints: Int = 0
    var placement: Int = 1  // 1, 2, 3, or 4

    init(finalPoints: Int, placement: Int) {
        self.finalPoints = finalPoints
        self.placement = placement
    }
}
