import SwiftUI
import SwiftData

struct StartView: View {
    var onReturnToMenu: () -> Void
    @Environment(\.modelContext) private var context

    @State private var playerNames = ["Player 1", "Player 2", "Player 3", "Player 4"]
    @State private var playerEmojis = ["", "", "", ""]
    @State private var playerColors = ["", "", "", ""]
    @State private var selectedProfileIDs: [UUID?] = [nil, nil, nil, nil]
    @State private var profilePickerSlot: Int? = nil
    @State private var startingPoints = 10000
    @State private var multiplier = 1
    @State private var minFan = 3
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    ForEach(0..<4, id: \.self) { i in
                        Button {
                            profilePickerSlot = i
                        } label: {
                            HStack(spacing: 8) {
                                Text("P\(i + 1)")
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, alignment: .leading)
                                if !playerColors[i].isEmpty {
                                    Circle()
                                        .fill(Color(hex: playerColors[i]))
                                        .frame(width: 10, height: 10)
                                }
                                if !playerEmojis[i].isEmpty {
                                    Text(playerEmojis[i])
                                }
                                Text(playerNames[i])
                                    .foregroundColor(selectedProfileIDs[i] == nil ? .secondary : .primary)
                                    .fontWeight(selectedProfileIDs[i] == nil ? .regular : .semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button("Start Game") { startGame() }
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("New Game")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onReturnToMenu()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheetView(
                    startingPoints: $startingPoints,
                    multiplier: $multiplier,
                    minFan: $minFan
                )
            }
            .sheet(item: $profilePickerSlot) { slot in
                let usedIDs = Set(selectedProfileIDs.enumerated()
                    .filter { $0.offset != slot }
                    .compactMap { $0.element })
                ProfilePickerSheet(
                    slotLabel: "Player \(slot + 1)",
                    usedProfileIDs: usedIDs,
                    onSelect: { profile in
                        playerNames[slot] = profile.name
                        playerEmojis[slot] = profile.emoji
                        playerColors[slot] = profile.colorHex
                        selectedProfileIDs[slot] = profile.id
                    },
                    onClear: {
                        playerNames[slot] = "Player \(slot + 1)"
                        playerEmojis[slot] = ""
                        playerColors[slot] = ""
                        selectedProfileIDs[slot] = nil
                    }
                )
            }
        }
    }

    private static let defaultPalette = ["#E74C3C", "#3498DB", "#2ECC71", "#F39C12"]

    private func startGame() {
        let usedColors = Set(
            selectedProfileIDs.enumerated()
                .filter { $0.element != nil }
                .map { playerColors[$0.offset].lowercased() }
        )
        var available = Self.defaultPalette.filter { !usedColors.contains($0.lowercased()) }

        var resolvedColors = playerColors
        for i in 0..<4 where selectedProfileIDs[i] == nil {
            resolvedColors[i] = available.isEmpty
                ? Self.defaultPalette[i % Self.defaultPalette.count]
                : available.removeFirst()
        }

        let session = GameSession(
            playerNames: playerNames,
            playerEmojis: playerEmojis,
            playerColors: resolvedColors,
            profileIDs: selectedProfileIDs,
            startingPoints: startingPoints,
            multiplier: multiplier,
            minFan: minFan
        )
        context.insert(session)
    }
}

private struct SettingsSheetView: View {
    @Binding var startingPoints: Int
    @Binding var multiplier: Int
    @Binding var minFan: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $startingPoints, in: 1000...100000, step: 1000) {
                        HStack {
                            Text("Starting Points")
                            Spacer()
                            Text("\(startingPoints)")
                                .foregroundColor(.secondary)
                        }
                    }
                    Stepper(value: $multiplier, in: 1...1000) {
                        HStack {
                            Text("Multiplier")
                            Spacer()
                            Text("\(multiplier)×")
                                .foregroundColor(.secondary)
                        }
                    }
                    Stepper(value: $minFan, in: 0...5) {
                        HStack {
                            Text("Minimum Fan")
                            Spacer()
                            Text(minFan == 0 ? "None" : "\(minFan)")
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text("Multiplier scales all payments. At \(multiplier)×, a 3-fan tsumo pays \(ScoringEngine.points(for: 3) * multiplier) per player.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
