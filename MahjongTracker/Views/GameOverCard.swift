import SwiftUI

struct GameOverCard: View {
    let session: GameSession
    let isAutoEnd: Bool
    let onDone: () -> Void

    private var rankedPlayers: [PlayerRecord] {
        session.players.sorted { $0.points > $1.points }
    }

    private var biggestWin: ScoreRecord? {
        session.history
            .filter { $0.winType != .manual }
            .max { a, b in
                (a.deltas.map(abs).max() ?? 0) < (b.deltas.map(abs).max() ?? 0)
            }
    }

    private let placeLabels = ["🥇", "🥈", "🥉", "4️⃣"]

    var body: some View {
        ZStack {
            Color.black.opacity(MahjongTheme.Opacity.gameOverScrim)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("GAME OVER")
                        .font(.largeTitle.bold())
                        .foregroundColor(MahjongTheme.primaryText)
                    Text(isAutoEnd ? "North Round Complete" : "Game Ended")
                        .font(.subheadline)
                        .foregroundColor(MahjongTheme.secondaryText)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                Divider()
                    .background(Color.white.opacity(MahjongTheme.Opacity.cardDivider))

                // Rankings
                VStack(spacing: 12) {
                    ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { place, player in
                        HStack(spacing: 10) {
                            Text(placeLabels[place])
                                .font(.title3)

                            Text("\(player.emoji) \(player.name)")
                                .font(.body.weight(.semibold))
                                .foregroundColor(MahjongTheme.primaryText)
                                .lineLimit(1)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(player.points)")
                                    .font(.body.monospacedDigit())
                                    .foregroundColor(MahjongTheme.primaryText)

                                let delta = player.points - session.startingPoints
                                Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(delta >= 0 ? .green : .red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Biggest Win
                if let win = biggestWin {
                    Divider()
                        .background(Color.white.opacity(MahjongTheme.Opacity.cardDivider))

                    VStack(spacing: 4) {
                        Label("Biggest Win", systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MahjongTheme.dealerText)

                        Text(win.summary)
                            .font(.subheadline)
                            .foregroundColor(MahjongTheme.primaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }

                Divider()
                    .background(Color.white.opacity(MahjongTheme.Opacity.cardDivider))

                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MahjongTheme.tableFelt)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(MahjongTheme.centerCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.gameOverCard))
            .overlay(
                RoundedRectangle(cornerRadius: MahjongTheme.Radius.gameOverCard)
                    .stroke(Color.white.opacity(MahjongTheme.Opacity.overlayStroke), lineWidth: 1)
            )
            .padding(.horizontal, 32)
        }
    }
}
