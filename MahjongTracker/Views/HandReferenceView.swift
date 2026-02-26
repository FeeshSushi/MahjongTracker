import SwiftUI

private struct TileGroup {
    let suitName: String
    let tiles: [(emoji: String, name: String)]
}

private struct HandEntry: Identifiable {
    let id = UUID()
    let name: String
    let chineseName: String
    let fan: String
    let description: String
    let isHighlighted: Bool
}

private struct HandSection: Identifiable {
    let id = UUID()
    let title: String
    let entries: [HandEntry]
}

struct HandReferenceView: View {
    @Environment(\.dismiss) private var dismiss

    private static let tileGroups: [TileGroup] = [
        TileGroup(suitName: "Characters (Man 万)", tiles: [
            ("🀇","1"),("🀈","2"),("🀉","3"),("🀊","4"),("🀋","5"),
            ("🀌","6"),("🀍","7"),("🀎","8"),("🀏","9"),
        ]),
        TileGroup(suitName: "Circles (Pin 筒)", tiles: [
            ("🀙","1"),("🀚","2"),("🀛","3"),("🀜","4"),("🀝","5"),
            ("🀞","6"),("🀟","7"),("🀠","8"),("🀡","9"),
        ]),
        TileGroup(suitName: "Bamboo (Sou 索)", tiles: [
            ("🀐","1"),("🀑","2"),("🀒","3"),("🀓","4"),("🀔","5"),
            ("🀕","6"),("🀖","7"),("🀗","8"),("🀘","9"),
        ]),
        TileGroup(suitName: "Winds", tiles: [
            ("🀀","East"),("🀁","South"),("🀂","West"),("🀃","North"),
        ]),
        TileGroup(suitName: "Dragons", tiles: [
            ("🀄\u{FE0E}","Red (中)"),("🀅","Green (發)"),("🀆","White (白)"),
        ]),
    ]

    private static let sections: [HandSection] = [
        HandSection(title: "Flowers", entries: [
            HandEntry(name: "No Flowers", chineseName: "无花", fan: "1", description: "Have no flowers", isHighlighted: false),
            HandEntry(name: "Seat Flower", chineseName: "正花", fan: "1", description: "Have a flower matching your seat (E=1, S=2, W=3, N=4)", isHighlighted: false),
            HandEntry(name: "Set of Flowers", chineseName: "一台花", fan: "2", description: "Have 4 flowers of the same series", isHighlighted: false),
            HandEntry(name: "7 Flowers", chineseName: "花糊", fan: "3", description: "Draw 7 flowers — may win immediately", isHighlighted: false),
            HandEntry(name: "8 Flowers", chineseName: "八仙過海", fan: "8", description: "Draw 8 flowers — may win immediately", isHighlighted: false),
        ]),
        HandSection(title: "Winning Methods", entries: [
            HandEntry(name: "Self Draw", chineseName: "自摸", fan: "1", description: "Draw the winning tile yourself", isHighlighted: true),
            HandEntry(name: "Concealed Hand", chineseName: "門前清", fan: "1", description: "Win without calling chow, pong, or kong", isHighlighted: true),
            HandEntry(name: "Win on Final Tile", chineseName: "海底撈月", fan: "1", description: "Win by drawing or discarding the final wall tile", isHighlighted: false),
            HandEntry(name: "After a Kong", chineseName: "槓上自摸", fan: "1", description: "Win with the replacement tile after calling kong", isHighlighted: false),
            HandEntry(name: "After Multiple Kongs", chineseName: "槓上槓自摸", fan: "8", description: "Call kong multiple times in a row and win with replacement tile", isHighlighted: false),
            HandEntry(name: "Robbing a Kong", chineseName: "搶槓", fan: "1", description: "Win off a tile when another player calls kong to extend an open triplet", isHighlighted: false),
        ]),
        HandSection(title: "Suit-Based", entries: [
            HandEntry(name: "Mixed Flush", chineseName: "混一色", fan: "3", description: "Only tiles of a single suit plus honor tiles", isHighlighted: true),
            HandEntry(name: "Pure Flush", chineseName: "清一色", fan: "7", description: "Only tiles of a single suit (no honors)", isHighlighted: true),
        ]),
        HandSection(title: "Honor Tiles", entries: [
            HandEntry(name: "Dragon Triplet", chineseName: "箭刻", fan: "1", description: "Triplet of any dragon tile (中發白)", isHighlighted: true),
            HandEntry(name: "Round Wind", chineseName: "圈風刻", fan: "1", description: "Triplet of the current prevailing wind", isHighlighted: true),
            HandEntry(name: "Seat Wind", chineseName: "門風刻", fan: "1", description: "Triplet of your seat wind", isHighlighted: true),
            HandEntry(name: "Small Three Dragons", chineseName: "小三元", fan: "5", description: "2 dragon triplets + pair of the 3rd (don't count individual dragon triplets)", isHighlighted: false),
            HandEntry(name: "Big Three Dragons", chineseName: "大三元", fan: "8", description: "Triplets of all 3 dragons (don't count individual dragon triplets)", isHighlighted: false),
            HandEntry(name: "Small Four Winds", chineseName: "小四喜", fan: "6", description: "Triplets of 3 winds + pair of 4th (doesn't stack with mixed flush; don't count individual wind triplets)", isHighlighted: false),
            HandEntry(name: "Big Four Winds", chineseName: "大四喜", fan: "Limit", description: "Triplets of all 4 winds", isHighlighted: false),
            HandEntry(name: "All Honors", chineseName: "字一色", fan: "10", description: "Hand contains only honor tiles (winds and dragons)", isHighlighted: false),
        ]),
        HandSection(title: "Triplet Hands", entries: [
            HandEntry(name: "All Triplets", chineseName: "碰碰糊", fan: "3", description: "Hand only contains triplets and a pair", isHighlighted: true),
            HandEntry(name: "Four Concealed Triplets", chineseName: "坎坎胡", fan: "8", description: "Hand only contains triplets, all self-drawn", isHighlighted: false),
            HandEntry(name: "Mixed Terminals", chineseName: "混老头", fan: "4", description: "Hand only contains terminals (1s and 9s) and honors", isHighlighted: false),
            HandEntry(name: "All Terminals", chineseName: "清老頭", fan: "Limit", description: "Hand only contains terminals (1s and 9s)", isHighlighted: false),
            HandEntry(name: "Four Kongs", chineseName: "十八羅漢", fan: "Limit", description: "Hand contains 4 kongs", isHighlighted: false),
        ]),
        HandSection(title: "Sequence Hands", entries: [
            HandEntry(name: "All Sequences", chineseName: "平糊", fan: "1", description: "Only sequences and a pair", isHighlighted: true),
        ]),
        HandSection(title: "Special Hands", entries: [
            HandEntry(name: "Thirteen Orphans", chineseName: "十三幺", fan: "Limit", description: "One of each terminal and honor, plus a pair of one of them", isHighlighted: false),
            HandEntry(name: "Nine Gates", chineseName: "九子連環", fan: "Limit", description: "Concealed 1112345678999, wins on any tile 1–9", isHighlighted: false),
            HandEntry(name: "Blessing of Heaven", chineseName: "天糊", fan: "Limit", description: "Win on the first turn as dealer", isHighlighted: false),
            HandEntry(name: "Blessing of Earth", chineseName: "地糊", fan: "Limit", description: "Win on the dealer's first discard", isHighlighted: false),
            HandEntry(name: "Blessing of Man", chineseName: "人糊", fan: "Limit", description: "Win on the first turn as non-dealer", isHighlighted: false),
        ]),
        HandSection(title: "Optional Hands", entries: [
            HandEntry(name: "Seven Pairs", chineseName: "七對子", fan: "3", description: "Hand contains 7 pairs", isHighlighted: false),
            HandEntry(name: "Three Kongs", chineseName: "三槓子", fan: "3", description: "Hand contains 3 kongs", isHighlighted: false),
            HandEntry(name: "Pure Straight", chineseName: "一條龍", fan: "3", description: "Have sequences 123, 456, 789 in the same suit", isHighlighted: false),
            HandEntry(name: "Mixed Triple Sequence", chineseName: "三相逢", fan: "3", description: "Same numbered sequence in each suit (e.g. 567 in all three suits)", isHighlighted: false),
            HandEntry(name: "Two Identical Sequences", chineseName: "一般高", fan: "1", description: "Two of the same sequence in the same suit (e.g. 123 123 in dots)", isHighlighted: false),
            HandEntry(name: "Three Identical Sequences", chineseName: "三般高", fan: "3", description: "Three of the same sequence in the same suit", isHighlighted: false),
            HandEntry(name: "Four Identical Sequences", chineseName: "四般高", fan: "Limit", description: "Four of the same sequence in the same suit", isHighlighted: false),
        ]),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Tile Reference") {
                    ForEach(HandReferenceView.tileGroups, id: \.suitName) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.suitName)
                                .font(.caption.bold())
                                .foregroundColor(MahjongTheme.secondaryText)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(group.tiles, id: \.name) { tile in
                                        VStack(spacing: 2) {
                                            Text(tile.emoji)
                                                .font(MahjongTheme.Font.tileEmoji)
                                            Text(tile.name)
                                                .font(.caption)
                                                .foregroundColor(MahjongTheme.secondaryText)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(MahjongTheme.tileBackground)

                Section("Fan → Points Table") {
                    let pairs = stride(from: 0, to: 13, by: 2).map { i -> ((Int, Int), (Int, Int)?) in
                        let a = (i, ScoringEngine.fanPointsTable[i])
                        let b = (i + 1 < 13) ? (i + 1, ScoringEngine.fanPointsTable[i + 1]) : nil
                        return (a, b)
                    }
                    ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                        HStack(spacing: 0) {
                            Text("\(pair.0.0) fan")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.caption.monospacedDigit())
                                .foregroundColor(MahjongTheme.primaryText)
                            Text("\(pair.0.1) pts")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.caption.monospacedDigit())
                                .foregroundColor(MahjongTheme.secondaryText)
                            Spacer().frame(width: MahjongTheme.Layout.tableColumnGap)
                            if let second = pair.1 {
                                Text("\(second.0) fan")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(MahjongTheme.primaryText)
                                Text("\(second.1) pts")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(MahjongTheme.secondaryText)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                                Spacer().frame(maxWidth: .infinity)
                            }
                        }
                    }
                    HStack(spacing: 0) {
                        Text("13+ fan")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(MahjongTheme.primaryText)
                        Text("384 pts (Limit)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(MahjongTheme.dealerText)
                        Spacer().frame(width: 24)
                        Spacer().frame(maxWidth: .infinity)
                        Spacer().frame(maxWidth: .infinity)
                    }
                }
                .listRowBackground(MahjongTheme.tileBackground)

                ForEach(HandReferenceView.sections) { section in
                    Section(section.title) {
                        ForEach(section.entries) { entry in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(entry.name)
                                            .font(.subheadline)
                                            .foregroundColor(MahjongTheme.primaryText)
                                        Text(entry.chineseName)
                                            .font(.caption)
                                            .foregroundColor(MahjongTheme.secondaryText)
                                    }
                                    Spacer()
                                    Text(entry.fan == "Limit" ? "Limit" : "\(entry.fan) fan")
                                        .font(.caption.bold())
                                        .foregroundColor(entry.fan == "Limit" ? MahjongTheme.dealerText : MahjongTheme.primaryText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            entry.fan == "Limit"
                                                ? MahjongTheme.dealerText.opacity(0.15)
                                                : Color.white.opacity(0.12)
                                        )
                                        .clipShape(Capsule())
                                }
                                Text(entry.description)
                                    .font(.caption)
                                    .foregroundColor(MahjongTheme.secondaryText)
                            }
                            .padding(.vertical, 2)
                            .listRowBackground(
                                entry.isHighlighted ? MahjongTheme.tableFelt.opacity(0.35) : MahjongTheme.tileBackground
                            )
                        }
                    }
                }

                Section {
                    Text("Green background = most important hands to remember. Optional hands are non-traditional and should be agreed upon before the game.")
                        .font(.caption)
                        .foregroundColor(MahjongTheme.secondaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MahjongTheme.panelDark)
            .listRowSeparatorTint(Color.white.opacity(0.10))
            .navigationTitle("Hand Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.panelDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MahjongTheme.primaryText)
                }
            }
        }
    }
}
