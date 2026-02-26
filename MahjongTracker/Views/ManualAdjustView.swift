import SwiftUI

struct ManualAdjustView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlayerIndex: Int = 0
    @State private var amountString: String = ""
    @State private var reason: String = ""

    var amount: Int { Int(amountString) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    Picker("Player", selection: $selectedPlayerIndex) {
                        ForEach(session.players.indices, id: \.self) { i in
                            Text("\(session.players[i].name) (\(session.players[i].points) pts)")
                                .foregroundColor(MahjongTheme.primaryText)
                                .tag(i)
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
                            Text(session.players[selectedPlayerIndex].name)
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
        deltas[selectedPlayerIndex] = amount

        let note = reason.isEmpty ? "Manual adjustment" : reason
        let playerName = session.players[selectedPlayerIndex].name
        let sign = amount >= 0 ? "+" : ""

        let entry = ScoreEntry(
            prevailingWind: session.prevailingWind,
            dealerSeatIndex: session.dealerSeatIndex,
            honba: session.honba,
            winType: .manual,
            winnerIndex: -1,
            discarderIndex: nil,
            fan: 0,
            deltas: deltas,
            summary: "\(playerName): \(sign)\(amount) (\(note))"
        )
        session.applyManualAdjust(deltas: deltas, entry: entry)
    }
}
