import SwiftUI

struct FoulHandView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    @State private var offenderSeatIndex: Int = 0

    private var sortedPlayers: [PlayerRecord] {
        session.players.sorted { $0.seatIndex < $1.seatIndex }
    }

    private var deltas: [Int] {
        ScoringEngine.foulHandDeltas(
            penalty: session.foulPenalty,
            offenderSeatIndex: offenderSeatIndex
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Offender") {
                    PlayerSegmentedPicker(players: sortedPlayers, selection: $offenderSeatIndex)
                        .listRowInsets(MahjongTheme.Layout.formRowInset)
                }
                .listRowBackground(MahjongTheme.tileBackground)

                Section("Penalty Preview") {
                    HStack {
                        Text("Flat penalty")
                            .foregroundColor(MahjongTheme.secondaryText)
                        Spacer()
                        Text("\(session.foulPenalty) pts per player")
                            .foregroundColor(MahjongTheme.secondaryText)
                    }
                    .font(.caption)

                    ForEach(sortedPlayers) { player in
                        let delta = deltas[player.seatIndex]
                        HStack {
                            if !player.emoji.isEmpty { Text(player.emoji) }
                            Text(player.name)
                                .foregroundColor(MahjongTheme.primaryText)
                            Text(session.seatWind(forSeat: player.seatIndex).character)
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
            .navigationTitle("False Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.feltDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        confirmFoulHand()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func confirmFoulHand() {
        let d = deltas
        let offender = session.player(atSeat: offenderSeatIndex)
        let record = ScoreRecord(
            prevailingWind: session.prevailingWind,
            dealerSeatIndex: session.dealerSeatIndex,
            honba: session.honba,
            winType: .foulHand,
            winnerSeatIndex: offenderSeatIndex,
            discarderSeatIndex: nil,
            fan: 0,
            deltas: d,
            summary: ScoringEngine.summaryString(
                winnerName: offender?.name ?? "Unknown",
                winType: .foulHand,
                fan: 0,
                discarderName: nil,
                winnerDelta: d[offenderSeatIndex]
            )
        )
        session.applyFoulHand(deltas: d, record: record)
    }
}
