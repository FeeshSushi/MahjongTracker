import SwiftUI

struct HistoryRowView: View {
    let entry: ScoreEntry
    let players: [PlayerState]

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.summary)
                            .font(.subheadline)
                            .foregroundColor(MahjongTheme.primaryText)
                            .multilineTextAlignment(.leading)
                        Text("\(entry.prevailingWind.character)\(entry.dealerSeatIndex + 1)" +
                             (entry.honba > 0 ? " · \(entry.honba)本" : "") +
                             " · \(formattedTime(entry.timestamp))")
                            .font(.caption)
                            .foregroundColor(MahjongTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(MahjongTheme.secondaryText)
                        .padding(.top, 3)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                Divider()
                    .overlay(Color.white.opacity(0.15))
                ForEach(Array(players.enumerated()), id: \.offset) { i, player in
                    if i < entry.deltas.count {
                        let delta = entry.deltas[i]
                        HStack {
                            Text(player.name)
                                .font(.caption)
                                .foregroundColor(MahjongTheme.primaryText)
                            Spacer()
                            Text(delta == 0 ? "—" : (delta > 0 ? "+\(delta)" : "\(delta)"))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(delta > 0 ? .green : delta < 0 ? .red : MahjongTheme.secondaryText)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
