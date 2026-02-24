import Foundation

enum ScoringEngine {

    // Fan-to-points table from HK Mahjong scoring guide.
    // Doubles up to 4 fan, then every 2 fan doubles from that point.
    // Index = fan count; index 13 = limit hand (384).
    static let fanPointsTable: [Int] = [
        1,   // 0 fan
        2,   // 1 fan
        4,   // 2 fan
        8,   // 3 fan
        16,  // 4 fan
        24,  // 5 fan
        32,  // 6 fan
        48,  // 7 fan
        64,  // 8 fan
        96,  // 9 fan
        128, // 10 fan
        192, // 11 fan
        256, // 12 fan
        384  // 13+ fan (limit)
    ]

    static let limitFan = 13
    static let limitPoints = 384

    static func points(for fan: Int) -> Int {
        if fan >= limitFan { return limitPoints }
        if fan < 0 { return fanPointsTable[0] }
        return fanPointsTable[fan]
    }

    // Tsumo: all 3 losers each pay points(fan) × multiplier to winner.
    static func tsumoDeltas(fan: Int, multiplier: Int, winnerIndex: Int) -> [Int] {
        let payment = points(for: fan) * multiplier
        var deltas = Array(repeating: -payment, count: 4)
        deltas[winnerIndex] = payment * 3
        return deltas
    }

    // Deal-in (全铳制): discarder alone pays 2 × points(fan) × multiplier.
    static func dealInDeltas(fan: Int, multiplier: Int, winnerIndex: Int, discarderIndex: Int) -> [Int] {
        let payment = points(for: fan) * multiplier * 2
        var deltas = Array(repeating: 0, count: 4)
        deltas[discarderIndex] = -payment
        deltas[winnerIndex] = payment
        return deltas
    }

    static func previewLines(
        fan: Int,
        multiplier: Int,
        winType: WinType,
        winnerIndex: Int,
        discarderIndex: Int?,
        players: [PlayerState]
    ) -> [(name: String, delta: Int)] {
        let deltas: [Int]
        switch winType {
        case .tsumo:
            deltas = tsumoDeltas(fan: fan, multiplier: multiplier, winnerIndex: winnerIndex)
        case .dealIn:
            guard let di = discarderIndex else { return [] }
            deltas = dealInDeltas(fan: fan, multiplier: multiplier, winnerIndex: winnerIndex, discarderIndex: di)
        case .manual:
            return []
        }
        return players.enumerated().map { idx, p in (name: p.name, delta: deltas[idx]) }
    }

    static func summaryString(
        winnerName: String,
        winType: WinType,
        fan: Int,
        discarderName: String?,
        winnerDelta: Int
    ) -> String {
        let sign = winnerDelta >= 0 ? "+" : ""
        let fanStr = fan >= limitFan ? "Limit" : "\(fan) fan"
        switch winType {
        case .tsumo:
            return "\(winnerName) tsumo \(fanStr) (\(sign)\(winnerDelta))"
        case .dealIn:
            let from = discarderName.map { " off \($0)" } ?? ""
            return "\(winnerName) wins \(fanStr)\(from) (\(sign)\(winnerDelta))"
        case .manual:
            return "Manual adjustment"
        }
    }
}
