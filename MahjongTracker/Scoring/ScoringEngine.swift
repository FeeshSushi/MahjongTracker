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

    // Tsumo: all 3 losers each pay (points(fan) × multiplier + honba × 100) to winner.
    // Honba rule: each honba adds 100 pts per payer (300 total extra for winner).
    static func tsumoDeltas(fan: Int, multiplier: Int, winnerSeatIndex: Int, honba: Int) -> [Int] {
        let base = points(for: fan) * multiplier
        let bonus = honba * 100
        var deltas = Array(repeating: -(base + bonus), count: 4)
        deltas[winnerSeatIndex] = (base + bonus) * 3
        return deltas
    }

    // Deal-in (全铳制): discarder alone pays 2 × points(fan) × multiplier + honba × 100.
    // Honba rule: discarder pays 100 extra per honba; winner receives same.
    static func dealInDeltas(
        fan: Int, multiplier: Int, winnerSeatIndex: Int, discarderSeatIndex: Int, honba: Int
    ) -> [Int] {
        let base = points(for: fan) * multiplier * 2
        let bonus = honba * 100
        var deltas = Array(repeating: 0, count: 4)
        deltas[discarderSeatIndex] = -(base + bonus)
        deltas[winnerSeatIndex] = base + bonus
        return deltas
    }

    // False win: offender pays flat penalty to each of the other 3 players.
    // Not scaled by multiplier — penalty is always the flat configured amount.
    static func foulHandDeltas(penalty: Int, offenderSeatIndex: Int) -> [Int] {
        var deltas = Array(repeating: penalty, count: 4)
        deltas[offenderSeatIndex] = -(penalty * 3)
        return deltas
    }

    static func previewLines(
        fan: Int,
        multiplier: Int,
        winType: WinType,
        winnerSeatIndex: Int,
        discarderSeatIndex: Int?,
        players: [PlayerRecord],
        honba: Int
    ) -> [(name: String, delta: Int)] {
        let deltas: [Int]
        switch winType {
        case .tsumo:
            deltas = tsumoDeltas(fan: fan, multiplier: multiplier,
                                 winnerSeatIndex: winnerSeatIndex, honba: honba)
        case .dealIn:
            guard let di = discarderSeatIndex else { return [] }
            deltas = dealInDeltas(fan: fan, multiplier: multiplier,
                                  winnerSeatIndex: winnerSeatIndex,
                                  discarderSeatIndex: di, honba: honba)
        case .manual, .foulHand, .drawOut:
            return []
        }
        return players
            .sorted { $0.seatIndex < $1.seatIndex }
            .map { p in (name: p.name, delta: deltas[p.seatIndex]) }
    }

    static func summaryString(
        winnerName: String,
        winType: WinType,
        fan: Int,
        discarderName: String?,
        winnerDelta: Int,
        honba: Int = 0
    ) -> String {
        let sign = winnerDelta >= 0 ? "+" : ""
        let fanStr = fan >= limitFan ? "Limit" : "\(fan) fan"
        let honbaSuffix = honba > 0 ? " +\(honba)本" : ""
        switch winType {
        case .tsumo:
            return "\(winnerName) tsumo \(fanStr)\(honbaSuffix) (\(sign)\(winnerDelta))"
        case .dealIn:
            let from = discarderName.map { " off \($0)" } ?? ""
            return "\(winnerName) wins \(fanStr)\(from)\(honbaSuffix) (\(sign)\(winnerDelta))"
        case .manual:
            return "Manual adjustment"
        case .foulHand:
            let penalty = abs(winnerDelta) / 3
            return "\(winnerName) false win (-\(penalty * 3))"
        case .drawOut:
            return "Draw out — no winner"
        }
    }
}
