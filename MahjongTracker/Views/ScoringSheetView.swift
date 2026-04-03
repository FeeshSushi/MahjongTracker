import SwiftUI

struct ScoringSheetView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    @State private var winType: WinType
    @State private var winnerSeatIndex: Int
    @State private var discarderSeatIndex: Int
    @State private var fan: Int = 3
    @State private var isLimitHand = false

    init(session: GameSession, preselectWinnerSeatIndex: Int? = nil) {
        self.session = session
        let winner = preselectWinnerSeatIndex ?? 0
        self._winnerSeatIndex = State(initialValue: winner)
        self._discarderSeatIndex = State(initialValue: winner == 0 ? 1 : 0)
        self._winType = State(initialValue: .dealIn)
    }

    var effectiveFan: Int { isLimitHand ? ScoringEngine.limitFan : fan }

    var effectiveDiscarderSeatIndex: Int {
        discarderSeatIndex == winnerSeatIndex ? (winnerSeatIndex + 1) % 4 : discarderSeatIndex
    }

    var deltas: [Int] {
        switch winType {
        case .tsumo:
            return ScoringEngine.tsumoDeltas(
                fan: effectiveFan,
                multiplier: session.multiplier,
                winnerSeatIndex: winnerSeatIndex,
                honba: session.honba
            )
        case .dealIn:
            return ScoringEngine.dealInDeltas(
                fan: effectiveFan,
                multiplier: session.multiplier,
                winnerSeatIndex: winnerSeatIndex,
                discarderSeatIndex: effectiveDiscarderSeatIndex,
                honba: session.honba
            )
        case .manual, .foulHand, .drawOut:
            return Array(repeating: 0, count: 4)
        }
    }

    var canConfirm: Bool {
        session.minFan == 0 || effectiveFan >= session.minFan
    }

    private var sortedPlayers: [PlayerRecord] {
        session.players.sorted { $0.seatIndex < $1.seatIndex }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Win Type") {
                    Picker("Win Type", selection: $winType) {
                        Text("Tsumo (Self-Draw)").tag(WinType.tsumo)
                        Text("Deal-in (Discard)").tag(WinType.dealIn)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(MahjongTheme.Layout.formRowInset)
                }
                .listRowBackground(MahjongTheme.tileBackground)

                Section("Winner") {
                    PlayerSegmentedPicker(players: sortedPlayers, selection: $winnerSeatIndex)
                        .listRowInsets(MahjongTheme.Layout.formRowInset)
                }
                .listRowBackground(MahjongTheme.tileBackground)

                if winType == .dealIn {
                    Section("Discarder") {
                        PlayerSegmentedPicker(
                            players: sortedPlayers,
                            selection: $discarderSeatIndex,
                            excludeSeatIndex: winnerSeatIndex
                        )
                        .listRowInsets(MahjongTheme.Layout.formRowInset)
                    }
                    .listRowBackground(MahjongTheme.tileBackground)
                }

                Section("Fan Count") {
                    Toggle("Limit Hand (13+ fan = 384 pts)", isOn: $isLimitHand)
                        .foregroundColor(MahjongTheme.primaryText)

                    if !isLimitHand {
                        Stepper(value: $fan, in: 0...12) {
                            HStack {
                                Text("\(fan) fan")
                                    .font(.headline)
                                    .foregroundColor(MahjongTheme.primaryText)
                                Spacer()
                                Text("\(ScoringEngine.points(for: fan)) pts")
                                    .foregroundColor(MahjongTheme.secondaryText)
                            }
                        }
                    }
                }
                .listRowBackground(MahjongTheme.tileBackground)

                if !canConfirm {
                    Section {
                        Label(
                            "Minimum \(session.minFan) fan required to win",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(.orange)
                    }
                    .listRowBackground(MahjongTheme.tileBackground)
                }

                Section("Payment Preview") {
                    if session.honba > 0 {
                        Label("Includes \(session.honba)本 bonus", systemImage: "plus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    ForEach(sortedPlayers) { p in
                        let delta = deltas[p.seatIndex]
                        HStack {
                            if !p.emoji.isEmpty { Text(p.emoji) }
                            Text(p.name)
                                .foregroundColor(MahjongTheme.primaryText)
                            Text(session.seatWind(forSeat: p.seatIndex).character)
                                .font(.caption)
                                .foregroundColor(MahjongTheme.secondaryText)
                            Spacer()
                            Text(delta == 0 ? "—" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                                .font(.headline.monospacedDigit())
                                .foregroundColor(delta > 0 ? .green : delta < 0 ? .red : MahjongTheme.secondaryText)
                        }
                    }
                }
                .listRowBackground(MahjongTheme.tileBackground)
            }
            .scrollContentBackground(.hidden)
            .background(MahjongTheme.feltDark)
            .navigationTitle("Score Hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.feltDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        confirmScoring()
                        dismiss()
                    }
                    .disabled(!canConfirm)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: winnerSeatIndex) { _, newWinner in
                if discarderSeatIndex == newWinner {
                    discarderSeatIndex = (newWinner + 1) % 4
                }
            }
        }
    }

    private func confirmScoring() {
        let d = deltas
        let dealerWon = (winnerSeatIndex == session.dealerSeatIndex)
        let winner = session.player(atSeat: winnerSeatIndex)
        let discarderName: String? = winType == .dealIn
            ? session.player(atSeat: effectiveDiscarderSeatIndex)?.name
            : nil

        let record = ScoreRecord(
            prevailingWind: session.prevailingWind,
            dealerSeatIndex: session.dealerSeatIndex,
            honba: session.honba,
            winType: winType,
            winnerSeatIndex: winnerSeatIndex,
            discarderSeatIndex: winType == .dealIn ? effectiveDiscarderSeatIndex : nil,
            fan: effectiveFan,
            deltas: d,
            summary: ScoringEngine.summaryString(
                winnerName: winner?.name ?? "Unknown",
                winType: winType,
                fan: effectiveFan,
                discarderName: discarderName,
                winnerDelta: d[winnerSeatIndex],
                honba: session.honba
            )
        )
        session.applyScore(deltas: d, record: record, dealerWon: dealerWon)
    }
}

// MARK: - Player Segmented Picker

struct PlayerSegmentedPicker: View {
    let players: [PlayerRecord]  // expected already sorted by seatIndex
    @Binding var selection: Int  // seatIndex
    var excludeSeatIndex: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(players) { player in
                if player.seatIndex != excludeSeatIndex {
                    let color = player.colorHex.isEmpty ? Color.blue : Color(hex: player.colorHex)
                    let isSelected = selection == player.seatIndex

                    Button {
                        selection = player.seatIndex
                    } label: {
                        VStack(spacing: 1) {
                            if !player.emoji.isEmpty {
                                Text(player.emoji).font(.caption)
                            }
                            Text(player.name)
                                .font(.caption.weight(isSelected ? .semibold : .regular))
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? .white : color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isSelected ? color : color.opacity(MahjongTheme.Opacity.unselectedPlayer))
                        .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.playerButton))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.pickerContainer))
    }
}
