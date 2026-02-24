import SwiftUI

struct SplashView: View {
    var hasActiveGame: Bool
    var onNewGame: () -> Void
    var onContinue: () -> Void

    @State private var showPlayers = false

    var body: some View {
        ZStack {
            MahjongTheme.feltDark.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("MahjongIcon").resizable().scaledToFit().padding()
                VStack(spacing: 8) {
                    Text("MahjongTracker")
                        .font(.largeTitle.bold())
                        .foregroundColor(MahjongTheme.primaryText)
                    Text("HK Style")
                        .font(.subheadline)
                        .foregroundColor(MahjongTheme.secondaryText)
                }

                if hasActiveGame {
                    HStack(spacing: 12) {
                        Button { onContinue() }
                        label: {
                            Text("Continue")
                                .font(.title.weight(.semibold))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 20)
                        }
                            .buttonStyle(.borderedProminent)
                            .tint(MahjongTheme.tableFelt)
                        Button { onNewGame() }
                        label: {
                            Text("New Game")
                                .font(.title.weight(.semibold))
                                .padding(.vertical, 20)
                                .padding(.horizontal, 20)
                        }
                            .buttonStyle(.bordered)
                            .tint(.white)
                    }
                    .padding()
                } else {
                    Button {
                        onNewGame()
                    } label: {
                        Text(
                            "Play"
                        ).font(.title.weight(.semibold))
                            .padding(.vertical, 20)
                            .padding(.horizontal, 60)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MahjongTheme.tableFelt)
                }

                Button("Players") { showPlayers = true }
                    .font(.subheadline)
                    .foregroundColor(MahjongTheme.secondaryText)
            }
        }
        .sheet(isPresented: $showPlayers) { PlayersView() }
    }
}
