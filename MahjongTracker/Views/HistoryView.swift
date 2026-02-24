import SwiftUI

struct HistoryView: View {
    @Bindable var session: GameSession
    @Environment(\.dismiss) private var dismiss

    var reversedHistory: [ScoreEntry] {
        session.history.reversed()
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.history.isEmpty {
                    ContentUnavailableView(
                        "No History Yet",
                        systemImage: "clock",
                        description: Text("Scored hands will appear here.")
                    )
                } else {
                    List(reversedHistory) { entry in
                        HistoryRowView(entry: entry, players: session.players)
                    }
                }
            }
            .navigationTitle("Score History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
