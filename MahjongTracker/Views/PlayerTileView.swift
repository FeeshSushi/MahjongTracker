import SwiftUI

struct PlayerTileView: View {
    let player: PlayerState
    let seatWind: Wind
    let isDealer: Bool
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(seatWind.character)
                        .font(.caption.bold())
                        .foregroundColor(isDealer ? MahjongTheme.dealerText : MahjongTheme.secondaryText)
                    Spacer()
                    if isDealer {
                        Text("Dealer")
                            .font(.caption2.bold())
                            .foregroundColor(MahjongTheme.dealerText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MahjongTheme.dealerBorderColor.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 4) {
                    if !player.emoji.isEmpty {
                        Text(player.emoji)
                            .font(.body)
                    }
                    Text(player.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(MahjongTheme.primaryText)
                        .lineLimit(1)
                }
                Text("\(player.points)")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundColor(player.points < 0 ? .red : MahjongTheme.primaryText)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(isDealer ? MahjongTheme.dealerTileBackground : MahjongTheme.tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isDealer
                            ? MahjongTheme.dealerBorderColor.opacity(0.7)
                            : (player.colorHex.isEmpty ? Color.white.opacity(0.08) : Color(hex: player.colorHex).opacity(0.75)),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
