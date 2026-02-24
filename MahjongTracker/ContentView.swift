import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(
        filter: #Predicate<GameSession> { $0.isActive },
        sort: \GameSession.createdAt,
        order: .reverse
    )
    private var activeSessions: [GameSession]

    @Environment(\.modelContext) private var context
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView(
                    hasActiveGame: activeSessions.first != nil,
                    onNewGame: {
                        if let session = activeSessions.first {
                            session.isActive = false
                        }
                        showSplash = false
                    },
                    onContinue: {
                        showSplash = false
                    }
                )
            } else if let session = activeSessions.first {
                GameBoardView(session: session)
            } else {
                StartView(onReturnToMenu: { showSplash = true })
            }
        }
        .tint(MahjongTheme.tableFelt)
        .onChange(of: activeSessions.isEmpty) { _, isEmpty in
            if isEmpty { showSplash = true }
        }
    }
}
