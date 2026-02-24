import SwiftUI
import SwiftData

// Allows using Int as the item type for .sheet(item:)
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct GameBoardView: View {
    @Bindable var session: GameSession
    @Environment(\.modelContext) private var context

    @State private var scoringForPlayer: Int? = nil
    @State private var showManualAdjust = false
    @State private var showHistory = false
    @State private var showHandRef = false
    @State private var showEndGameAlert = false

    // Help tip
    @State private var showHelpTip = false
    @AppStorage("hasSeenHelpTip") private var hasSeenHelpTip = false

    // Intro animation
    private enum IntroPhase { case shuffling, dealerSpin, playing }
    @State private var introPhase: IntroPhase = .playing
    @State private var displayOrder: [Int] = [0, 1, 2, 3]  // visual slot → player index
    @State private var highlightedSlot: Int? = nil

    private let sideWidth: CGFloat = 96
    private let edgeHeight: CGFloat = 112

    var dealerRotation: Double {
        -Double(session.dealerSeatIndex) * 90.0
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let centerW = w - 2 * sideWidth
            let centerH = h - 2 * edgeHeight
            let boxSize = min(centerW, centerH)

            ZStack {
                MahjongTheme.feltDark
                    .ignoresSafeArea()

                // Top: slot 2
                tile(for: displayOrder[2])
                    .frame(width: w, height: edgeHeight - 10)
                    .rotationEffect(.degrees(180))
                    .position(x: w / 2, y: edgeHeight / 2)

                // Bottom: slot 0
                tile(for: displayOrder[0])
                    .frame(width: w, height: edgeHeight - 10)
                    .position(x: w / 2, y: h - edgeHeight / 2)

                // Left: slot 3
                tile(for: displayOrder[3])
                    .frame(width: centerH, height: sideWidth - 5)
                    .rotationEffect(.degrees(90))
                    .frame(width: sideWidth, height: centerH)
                    .position(x: sideWidth / 2, y: h / 2)

                // Right: slot 1
                tile(for: displayOrder[1])
                    .frame(width: centerH, height: sideWidth - 5)
                    .rotationEffect(.degrees(-90))
                    .frame(width: sideWidth, height: centerH)
                    .position(x: w - sideWidth / 2, y: h / 2)

                // Dealer highlight overlays (dealer spin phase)
                dealerHighlight(slot: 0, w: w, h: h, centerH: centerH)
                dealerHighlight(slot: 1, w: w, h: h, centerH: centerH)
                dealerHighlight(slot: 2, w: w, h: h, centerH: centerH)
                dealerHighlight(slot: 3, w: w, h: h, centerH: centerH)

                // Center box — square, rotates to face the dealer
                centerBox
                    .frame(width: boxSize, height: boxSize)
                    .rotationEffect(.degrees(introPhase == .playing ? dealerRotation : 0))
                    .position(x: w / 2, y: h / 2)

                // Help tooltip — fixed above the bottom tile
                if showHelpTip {
                    HelpTooltip {
                        withAnimation { showHelpTip = false }
                    }
                    .frame(maxWidth: 240)
                    .position(x: w / 2, y: h - edgeHeight - 60)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
                    .zIndex(10)
                }
            }
            .task {
                if !session.introCompleted {
                    introPhase = .shuffling
                    await runIntro(w: w, h: h)
                }
            }
            .task {
                if !hasSeenHelpTip && session.introCompleted {
                    hasSeenHelpTip = true
                    withAnimation { showHelpTip = true }
                    try? await Task.sleep(for: .seconds(3.5))
                    withAnimation { showHelpTip = false }
                }
            }
        }
        .padding(.horizontal, 2)
        .background(MahjongTheme.feltDark)
        .ignoresSafeArea(edges: .horizontal)
        .sheet(item: $scoringForPlayer) { playerIndex in
            ScoringSheetView(session: session, preselectWinnerIndex: playerIndex)
        }
        .sheet(isPresented: $showManualAdjust) {
            ManualAdjustView(session: session)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(session: session)
        }
        .sheet(isPresented: $showHandRef) {
            HandReferenceView()
        }
        .alert("End Game?", isPresented: $showEndGameAlert) {
            Button("End Game", role: .destructive) {
                session.isActive = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will end the current game. All scores are saved in history.")
        }
    }

    // MARK: - Intro Animation

    @MainActor
    private func runIntro(w: CGFloat, h: CGFloat) async {
        // --- Phase 1: Shuffle (≈3 s) ---
        let finalOrder = (0..<4).shuffled()

        var delays: [Double] = []
        var t = 0.07
        while delays.reduce(0, +) < 2.6 {
            delays.append(t)
            t = min(t * 1.13, 0.55)
        }

        for delay in delays.dropLast() {
            let intermediate = (0..<4).shuffled()
            withAnimation(.easeInOut(duration: delay * 0.7)) {
                displayOrder = intermediate
            }
            try? await Task.sleep(for: .seconds(delay))
        }
        withAnimation(.easeInOut(duration: 0.5)) { displayOrder = finalOrder }
        try? await Task.sleep(for: .seconds(0.7))

        // Reorder session.players to match the final display arrangement
        let snapshot = session.players
        var reordered = snapshot
        for (slot, idx) in finalOrder.enumerated() {
            reordered[slot] = snapshot[idx]
        }
        session.players = reordered
        displayOrder = [0, 1, 2, 3]

        // --- Phase 2: Dealer spin (≈3 s) ---
        introPhase = .dealerSpin
        let finalDealer = Int.random(in: 0..<4)

        let fullSteps = 16
        let extraSteps = (finalDealer - (fullSteps % 4) + 4) % 4
        let totalSteps = fullSteps + extraSteps + 1

        for step in 0..<totalSteps {
            let slot = step % 4
            let progress = Double(step) / Double(max(totalSteps - 1, 1))
            let delay = 0.05 + progress * progress * 0.45
            withAnimation(.easeInOut(duration: 0.1)) { highlightedSlot = slot }
            try? await Task.sleep(for: .seconds(delay))
        }

        withAnimation {
            highlightedSlot = finalDealer
            session.dealerSeatIndex = finalDealer
        }
        try? await Task.sleep(for: .seconds(0.9))

        // Complete intro
        session.introCompleted = true
        withAnimation { introPhase = .playing; highlightedSlot = nil }

        // Show help tip after intro (first time only)
        if !hasSeenHelpTip {
            hasSeenHelpTip = true
            withAnimation { showHelpTip = true }
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation { showHelpTip = false }
        }
    }

    // MARK: - Dealer highlight per slot

    @ViewBuilder
    private func dealerHighlight(slot: Int, w: CGFloat, h: CGFloat, centerH: CGFloat) -> some View {
        if highlightedSlot == slot {
            let glow = Color.yellow
            Group {
                switch slot {
                case 0: // bottom
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: w - 16, height: edgeHeight - 10)
                        .position(x: w / 2, y: h - edgeHeight / 2)
                case 1: // right
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: centerH - 16, height: sideWidth - 5)
                        .rotationEffect(.degrees(-90))
                        .frame(width: sideWidth, height: centerH)
                        .position(x: w - sideWidth / 2, y: h / 2)
                case 2: // top
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: w - 16, height: edgeHeight - 10)
                        .rotationEffect(.degrees(180))
                        .position(x: w / 2, y: edgeHeight / 2)
                case 3: // left
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: centerH - 16, height: sideWidth - 5)
                        .rotationEffect(.degrees(90))
                        .frame(width: sideWidth, height: centerH)
                        .position(x: sideWidth / 2, y: h / 2)
                default:
                    EmptyView()
                }
            }
            .transition(.opacity)
            .zIndex(5)
        }
    }

    // MARK: - Tile

    @ViewBuilder
    private func tile(for playerIndex: Int) -> some View {
        if playerIndex < session.players.count {
            PlayerTileView(
                player: session.players[playerIndex],
                seatWind: session.seatWind(for: playerIndex),
                isDealer: session.dealerSeatIndex == playerIndex,
                onTap: { if introPhase == .playing { scoringForPlayer = playerIndex } }
            )
        }
    }

    // MARK: - Center box

    @ViewBuilder
    private var centerBox: some View {
        VStack(spacing: 10) {
            // Phase-specific top content
            switch introPhase {
            case .shuffling:
                VStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundColor(MahjongTheme.primaryText)
                    Text("Shuffling Players...")
                        .font(.headline)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            case .dealerSpin:
                VStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.title2)
                        .foregroundColor(MahjongTheme.primaryText)
                    Text("Selecting the Dealer...")
                        .font(.headline)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            case .playing:
                VStack(spacing: 3) {
                    Text(session.prevailingWind.character)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(MahjongTheme.primaryText)
                    Text("\(session.prevailingWind.label) Round \(session.dealerRotationCount + 1)")
                        .font(.caption)
                        .foregroundColor(MahjongTheme.secondaryText)
                    if session.honba > 0 {
                        Text("本 \(session.honba)")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
            }

            if introPhase == .playing {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)

                Button {
                    showHandRef = true
                } label: {
                    Label("Hand Reference", systemImage: "book.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MahjongTheme.tableFelt)

                Menu {
                    Button("End Game", role: .destructive) {
                        showEndGameAlert = true
                    }
                    Divider()
                    Button {
                        showHistory = true
                    } label: {
                        Label("Score History", systemImage: "clock")
                    }
                    Button {
                        showManualAdjust = true
                    } label: {
                        Label("Manual Adjust", systemImage: "plusminus.circle")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .padding(12)
        .background(MahjongTheme.centerCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
            if introPhase == .playing {
                Button {
                    withAnimation { showHelpTip = true }
                    Task {
                        try? await Task.sleep(for: .seconds(3.5))
                        withAnimation { showHelpTip = false }
                    }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(MahjongTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Help Tooltip

private struct HelpTooltip: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Press on the winner's player card to enter their points and progress to the next round!")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)

            TooltipCaret()
                .fill(.regularMaterial)
                .frame(width: 14, height: 7)
        }
        .onTapGesture { onDismiss() }
    }
}

private struct TooltipCaret: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
