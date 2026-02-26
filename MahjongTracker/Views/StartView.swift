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
        ZStack {
            MahjongTheme.feltDeeper.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────
                HStack {
                    Button { onReturnToMenu() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(MahjongTheme.primaryText)
                    }
                    Spacer()
                    Text("New Game")
                        .font(.title)
                        .foregroundColor(MahjongTheme.primaryText)
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.title3).bold()
                            .foregroundColor(MahjongTheme.primaryText)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .background(MahjongTheme.feltDark.ignoresSafeArea(edges: .top))

                // ── Player slots ─────────────────────────────────────
                VStack(spacing: MahjongTheme.Layout.gridSpacing) {
                    ForEach(0..<4, id: \.self) { i in
                        Button { profilePickerSlot = i } label: {
                            HStack(spacing: 8) {
                                Text("P\(i + 1)")
                                    .foregroundColor(MahjongTheme.secondaryText)
                                    .frame(width: MahjongTheme.Layout.playerLabelWidth, alignment: .leading)
                                if !playerColors[i].isEmpty {
                                    Circle()
                                        .fill(Color(hex: playerColors[i]))
                                        .frame(width: MahjongTheme.Layout.colorDot, height: MahjongTheme.Layout.colorDot)
                                }
                                if !playerEmojis[i].isEmpty {
                                    Text(playerEmojis[i])
                                }
                                Text(playerNames[i])
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedProfileIDs[i] == nil ? MahjongTheme.secondaryText : MahjongTheme.primaryText)
                                    .fontWeight(selectedProfileIDs[i] == nil ? .regular : .semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(MahjongTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 14)
                            .background(MahjongTheme.tileBackground)
                            .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.tile))
                            .overlay(
                                RoundedRectangle(cornerRadius: MahjongTheme.Radius.tile)
                                    .stroke(
                                        selectedProfileIDs[i] != nil
                                            ? Color(hex: playerColors[i]).opacity(MahjongTheme.Opacity.customBorder)
                                            : Color.white.opacity(MahjongTheme.Opacity.tileBorder),
                                        lineWidth: selectedProfileIDs[i] != nil
                                            ? MahjongTheme.Layout.profileBorderWidth
                                            : MahjongTheme.Layout.tileBorderWidth
                                    )
                            )
                        }.buttonStyle(.plain)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal)
                .padding(.vertical, MahjongTheme.Layout.gridSpacing)

                // ── Start Game ───────────────────────────────────────
                Button { startGame() } label: {
                    Text("Start Game")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
                .buttonStyle(.borderedProminent)
                .tint(MahjongTheme.tableFelt)
                .padding(.horizontal)
                .padding(.bottom, 32)
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
                                .foregroundColor(MahjongTheme.primaryText)
                            Spacer()
                            Text("\(startingPoints)")
                                .foregroundColor(MahjongTheme.secondaryText)
                        }
                    }
                    Stepper(value: $multiplier, in: 1...1000) {
                        HStack {
                            Text("Multiplier")
                                .foregroundColor(MahjongTheme.primaryText)
                            Spacer()
                            Text("\(multiplier)×")
                                .foregroundColor(MahjongTheme.secondaryText)
                        }
                    }
                    Stepper(value: $minFan, in: 0...5) {
                        HStack {
                            Text("Minimum Fan")
                                .foregroundColor(MahjongTheme.primaryText)
                            Spacer()
                            Text(minFan == 0 ? "None" : "\(minFan)")
                                .foregroundColor(MahjongTheme.secondaryText)
                        }
                    }
                } footer: {
                    Text("Multiplier scales all payments. At \(multiplier)×, a 3-fan tsumo pays \(ScoringEngine.points(for: 3) * multiplier) per player.")
                        .foregroundColor(MahjongTheme.secondaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)
            }
            .scrollContentBackground(.hidden)
            .background(MahjongTheme.feltDark)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.feltDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
