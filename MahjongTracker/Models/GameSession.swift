import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MahjongTracker", category: "GameSession")

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
    var foulPenalty: Int = 384

    // Game state
    var prevailingWindRaw: Int = 0
    var dealerSeatIndex: Int = 0
    var dealerRotationCount: Int = 0  // how many times dealer has rotated in current prevailing wind
    var honba: Int = 0

    // Profile links: "UUID1,UUID2,nil,UUID4" — always 4 comma-separated tokens
    var profileIDsString: String = "nil,nil,nil,nil"

    // Relationships
    @Relationship(deleteRule: .cascade) var players: [PlayerRecord] = []
    @Relationship(deleteRule: .cascade) var history: [ScoreRecord] = []

    // MARK: - Computed properties

    var prevailingWind: Wind {
        get { Wind(rawValue: prevailingWindRaw) ?? .east }
        set { prevailingWindRaw = newValue.rawValue }
    }

    var profileIDs: [UUID?] {
        get {
            profileIDsString
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { $0 == "nil" ? nil : UUID(uuidString: String($0)) }
        }
        set {
            profileIDsString = newValue.map { $0?.uuidString ?? "nil" }.joined(separator: ",")
        }
    }

    var roundLabel: String {
        "\(prevailingWind.character)\(dealerRotationCount + 1)"
    }

    // MARK: - Player helpers

    func player(atSeat seatIndex: Int) -> PlayerRecord? {
        players.first { $0.seatIndex == seatIndex }
    }

    func seatWind(forSeat seatIndex: Int) -> Wind {
        let offset = (seatIndex - dealerSeatIndex + 4) % 4
        return Wind(rawValue: offset) ?? .east
    }

    // MARK: - Init

    init(
        playerNames: [String],
        playerEmojis: [String] = [],
        playerColors: [String] = [],
        profileIDs: [UUID?] = [],
        startingPoints: Int,
        multiplier: Int,
        minFan: Int,
        foulPenalty: Int = 384
    ) {
        self.startingPoints = startingPoints
        self.multiplier = multiplier
        self.minFan = minFan
        self.foulPenalty = foulPenalty
        self.players = playerNames.indices.map { i in
            PlayerRecord(
                name: playerNames[i],
                emoji: i < playerEmojis.count ? playerEmojis[i] : "",
                colorHex: i < playerColors.count ? playerColors[i] : "",
                points: startingPoints,
                seatIndex: i
            )
        }
        self.profileIDsString = profileIDs.map { $0?.uuidString ?? "nil" }.joined(separator: ",")
    }

    // MARK: - Game Actions

    func applyScore(deltas: [Int], record: ScoreRecord, dealerWon: Bool) {
        for player in players {
            player.points += deltas[player.seatIndex]
        }
        history.append(record)
        advanceRound(dealerWon: dealerWon)
    }

    func applyManualAdjust(deltas: [Int], record: ScoreRecord) {
        for player in players {
            player.points += deltas[player.seatIndex]
        }
        history.append(record)
    }

    func applyFoulHand(deltas: [Int], record: ScoreRecord) {
        for player in players {
            player.points += deltas[player.seatIndex]
        }
        history.append(record)
        advanceRound(dealerWon: true)  // dealer stays, honba increments
    }

    func applyDrawOut(record: ScoreRecord) {
        history.append(record)         // no point changes
        advanceRound(dealerWon: true)  // dealer stays, honba increments
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
