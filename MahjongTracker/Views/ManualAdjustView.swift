import SwiftUI

struct ManualAdjustView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSeatIndex: Int = 0
    @State private var amountString: String = ""
    @State private var reason: String = ""

    var amount: Int { Int(amountString) ?? 0 }

    private var sortedPlayers: [PlayerRecord] {
        session.players.sorted { $0.seatIndex < $1.seatIndex }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    Picker("Player", selection: $selectedSeatIndex) {
                        ForEach(sortedPlayers) { player in
                            Text("\(player.name) (\(player.points) pts)")
                                .foregroundColor(MahjongTheme.primaryText)
                                .tag(player.seatIndex)
                        }
                    }
                    .foregroundColor(MahjongTheme.primaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)

                Section("Adjustment") {
                    TextField("Amount (negative to deduct)", text: $amountString)
                        .foregroundColor(MahjongTheme.primaryText)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Reason (optional)", text: $reason)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)

                if amount != 0 {
                    Section("Preview") {
                        HStack {
                            Text(session.player(atSeat: selectedSeatIndex)?.name ?? "")
                                .foregroundColor(MahjongTheme.primaryText)
                            Spacer()
                            Text(amount > 0 ? "+\(amount)" : "\(amount)")
                                .font(.headline.monospacedDigit())
                                .foregroundColor(amount > 0 ? .green : .red)
                        }
                    }
                    .listRowBackground(MahjongTheme.tileBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(MahjongTheme.feltDark)
            .navigationTitle("Manual Adjust")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.feltDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyAdjustment()
                        dismiss()
                    }
                    .disabled(amount == 0)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyAdjustment() {
        var deltas = Array(repeating: 0, count: 4)
        deltas[selectedSeatIndex] = amount

        let note = reason.isEmpty ? "Manual adjustment" : reason
        let playerName = session.player(atSeat: selectedSeatIndex)?.name ?? "Player"
        let sign = amount >= 0 ? "+" : ""

        let record = ScoreRecord(
            prevailingWind: session.prevailingWind,
            dealerSeatIndex: session.dealerSeatIndex,
            honba: session.honba,
            winType: .manual,
            winnerSeatIndex: nil,
            discarderSeatIndex: nil,
            fan: 0,
            deltas: deltas,
            summary: "\(playerName): \(sign)\(amount) (\(note))"
        )
        session.applyManualAdjust(deltas: deltas, record: record)
    }
}
