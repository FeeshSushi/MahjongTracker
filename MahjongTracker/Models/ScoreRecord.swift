import Foundation
import SwiftData

enum WinType: String, Codable {
    case tsumo
    case dealIn
    case manual
    case foulHand  // false win — offender identified by winnerSeatIndex
    case drawOut   // no winner — all deltas zero, dealer stays, honba increments
}

@Model
final class ScoreRecord {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var prevailingWindRaw: Int = 0
    var dealerSeatIndex: Int = 0
    var honba: Int = 0
    var winTypeRaw: String = "tsumo"
    var winnerSeatIndex: Int? = nil   // nil for manual entries (replaces -1 sentinel)
    var discarderSeatIndex: Int? = nil
    var fan: Int = 0
    // Comma-separated ints, always 4 values indexed by seatIndex (0–3)
    var deltasString: String = "0,0,0,0"
    var summary: String = ""

    var prevailingWind: Wind {
        get { Wind(rawValue: prevailingWindRaw) ?? .east }
        set { prevailingWindRaw = newValue.rawValue }
    }

    var winType: WinType {
        get { WinType(rawValue: winTypeRaw) ?? .tsumo }
        set { winTypeRaw = newValue.rawValue }
    }

    // Deltas indexed by seatIndex (always length 4)
    var deltas: [Int] {
        get {
            let parts = deltasString.split(separator: ",", omittingEmptySubsequences: false)
            guard parts.count == 4,
                  let a = Int(parts[0]), let b = Int(parts[1]),
                  let c = Int(parts[2]), let d = Int(parts[3])
            else { return [0, 0, 0, 0] }
            return [a, b, c, d]
        }
        set {
            guard newValue.count == 4 else { return }
            deltasString = newValue.map(String.init).joined(separator: ",")
        }
    }

    init(
        prevailingWind: Wind,
        dealerSeatIndex: Int,
        honba: Int,
        winType: WinType,
        winnerSeatIndex: Int?,
        discarderSeatIndex: Int?,
        fan: Int,
        deltas: [Int],
        summary: String
    ) {
        self.prevailingWindRaw = prevailingWind.rawValue
        self.dealerSeatIndex = dealerSeatIndex
        self.honba = honba
        self.winTypeRaw = winType.rawValue
        self.winnerSeatIndex = winnerSeatIndex
        self.discarderSeatIndex = discarderSeatIndex
        self.fan = fan
        self.deltasString = deltas.map(String.init).joined(separator: ",")
        self.summary = summary
    }
}
