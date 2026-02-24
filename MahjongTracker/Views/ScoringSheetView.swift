import SwiftUI

struct ScoringSheetView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    @State private var winType: WinType
    @State private var winnerIndex: Int
    @State private var discarderIndex: Int
    @State private var fan: Int = 3
    @State private var isLimitHand = false

    init(session: GameSession, preselectWinnerIndex: Int? = nil) {
        self.session = session
        let winner = preselectWinnerIndex ?? 0
        self._winnerIndex = State(initialValue: winner)
        self._discarderIndex = State(initialValue: winner == 0 ? 1 : 0)
        self._winType = State(initialValue: .tsumo)
    }

    var effectiveFan: Int { isLimitHand ? ScoringEngine.limitFan : fan }

    var effectiveDiscarderIndex: Int {
        discarderIndex == winnerIndex ? (winnerIndex + 1) % 4 : discarderIndex
    }

    var deltas: [Int] {
        switch winType {
        case .tsumo:
            return ScoringEngine.tsumoDeltas(
                fan: effectiveFan,
                multiplier: session.multiplier,
                winnerIndex: winnerIndex
            )
        case .dealIn:
            return ScoringEngine.dealInDeltas(
                fan: effectiveFan,
                multiplier: session.multiplier,
                winnerIndex: winnerIndex,
                discarderIndex: effectiveDiscarderIndex
            )
        case .manual:
            return Array(repeating: 0, count: 4)
        }
    }

    var canConfirm: Bool {
        session.minFan == 0 || effectiveFan >= session.minFan
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
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section("Winner") {
                    Picker("Winner", selection: $winnerIndex) {
                        ForEach(session.players.indices, id: \.self) { i in
                            let p = session.players[i]
                            Text(p.emoji.isEmpty ? p.name : "\(p.emoji) \(p.name)").tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                if winType == .dealIn {
                    Section("Discarder") {
                        Picker("Discarder", selection: $discarderIndex) {
                            ForEach(session.players.indices, id: \.self) { i in
                                if i != winnerIndex {
                                    Text("\(session.players[i].name)  \(session.seatWind(for: i).character)")
                                        .tag(i)
                                }
                            }
                        }
                    }
                }

                Section("Fan Count") {
                    Toggle("Limit Hand (13+ fan = 384 pts)", isOn: $isLimitHand)

                    if !isLimitHand {
                        Stepper(value: $fan, in: 0...12) {
                            HStack {
                                Text("\(fan) fan")
                                    .font(.headline)
                                Spacer()
                                Text("\(ScoringEngine.points(for: fan)) pts")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !canConfirm {
                    Section {
                        Label(
                            "Minimum \(session.minFan) fan required to win",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(.orange)
                    }
                }

                Section("Payment Preview") {
                    ForEach(session.players.indices, id: \.self) { i in
                        let delta = deltas[i]
                        let p = session.players[i]
                        HStack {
                            if !p.emoji.isEmpty { Text(p.emoji) }
                            Text(p.name)
                            Text(session.seatWind(for: i).character)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(delta == 0 ? "—" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                                .font(.headline.monospacedDigit())
                                .foregroundColor(delta > 0 ? .green : delta < 0 ? .red : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Score Hand")
            .navigationBarTitleDisplayMode(.inline)
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
            .onChange(of: winnerIndex) { _, newWinner in
                if discarderIndex == newWinner {
                    discarderIndex = (newWinner + 1) % 4
                }
            }
        }
    }

    private func confirmScoring() {
        let d = deltas
        let dealerWon = (winnerIndex == session.dealerSeatIndex)
        let winner = session.players[winnerIndex]
        let discarderName: String? = winType == .dealIn ? session.players[effectiveDiscarderIndex].name : nil

        let entry = ScoreEntry(
            prevailingWind: session.prevailingWind,
            dealerSeatIndex: session.dealerSeatIndex,
            honba: session.honba,
            winType: winType,
            winnerIndex: winnerIndex,
            discarderIndex: winType == .dealIn ? effectiveDiscarderIndex : nil,
            fan: effectiveFan,
            deltas: d,
            summary: ScoringEngine.summaryString(
                winnerName: winner.name,
                winType: winType,
                fan: effectiveFan,
                discarderName: discarderName,
                winnerDelta: d[winnerIndex]
            )
        )
        session.applyScore(deltas: d, entry: entry, dealerWon: dealerWon)
    }
}
