import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var isActive: Bool = true
    var isPendingGameOver: Bool = false
    var introCompleted: Bool = false

    // Configuration (set at game start)
    var startingPoints: Int = 10000
    var multiplier: Int = 1
    var minFan: Int = 3

    // Game state
    var prevailingWindRaw: Int = 0
    var dealerSeatIndex: Int = 0
    var dealerRotationCount: Int = 0  // how many times dealer has rotated in current prevailing wind
    var honba: Int = 0

    // JSON-encoded data blobs
    var playersJSON: Data = Data()
    var historyJSON: Data = Data()
    var profileIDsJSON: Data = Data()

    // MARK: - Computed properties

    var prevailingWind: Wind {
        get { Wind(rawValue: prevailingWindRaw) ?? .east }
        set { prevailingWindRaw = newValue.rawValue }
    }

    var players: [PlayerState] {
        get { (try? JSONDecoder().decode([PlayerState].self, from: playersJSON)) ?? [] }
        set { playersJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var history: [ScoreEntry] {
        get { (try? JSONDecoder().decode([ScoreEntry].self, from: historyJSON)) ?? [] }
        set { historyJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var profileIDs: [UUID?] {
        get { (try? JSONDecoder().decode([UUID?].self, from: profileIDsJSON)) ?? [] }
        set { profileIDsJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    func seatWind(for playerIndex: Int) -> Wind {
        let offset = (playerIndex - dealerSeatIndex + 4) % 4
        return Wind(rawValue: offset) ?? .east
    }

    var roundLabel: String {
        "\(prevailingWind.character)\(dealerRotationCount + 1)"
    }

    // MARK: - Init

    init(playerNames: [String], playerEmojis: [String] = [], playerColors: [String] = [], profileIDs: [UUID?] = [], startingPoints: Int, multiplier: Int, minFan: Int) {
        self.startingPoints = startingPoints
        self.multiplier = multiplier
        self.minFan = minFan
        self.players = playerNames.indices.map { i in
            PlayerState(
                name: playerNames[i],
                emoji: i < playerEmojis.count ? playerEmojis[i] : "",
                colorHex: i < playerColors.count ? playerColors[i] : "",
                points: startingPoints
            )
        }
        self.history = []
        self.profileIDs = profileIDs
    }

    // MARK: - Game Actions

    func applyScore(deltas: [Int], entry: ScoreEntry, dealerWon: Bool) {
        var updated = players
        for i in updated.indices { updated[i].points += deltas[i] }
        players = updated

        var hist = history
        hist.append(entry)
        history = hist

        advanceRound(dealerWon: dealerWon)
    }

    func applyManualAdjust(deltas: [Int], entry: ScoreEntry) {
        var updated = players
        for i in updated.indices { updated[i].points += deltas[i] }
        players = updated

        var hist = history
        hist.append(entry)
        history = hist
        // No round advancement for manual adjustments
    }

    private func advanceRound(dealerWon: Bool) {
        if dealerWon {
            honba += 1
        } else {
            honba = 0
            dealerSeatIndex = (dealerSeatIndex + 1) % 4
            dealerRotationCount += 1
            if dealerRotationCount >= 4 {
                dealerRotationCount = 0
                if prevailingWind == .north {
                    isPendingGameOver = true
                } else {
                    prevailingWind = prevailingWind.next
                }
            }
        }
    }
}
