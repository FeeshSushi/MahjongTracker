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
    @State private var showGameOverCard = false
    @State private var gameOverIsAuto = false

    // Help tip
    @State private var showHelpTip = false
    @AppStorage("hasSeenHelpTip") private var hasSeenHelpTip = false

    // Intro animation
    private enum IntroPhase { case shuffling, dealerSpin, playing }
    @State private var introPhase: IntroPhase = .playing
    @State private var displayOrder: [Int] = [0, 1, 2, 3]  // visual slot → player index
    @State private var highlightedSlot: Int? = nil

    // Splash text overlay
    @State private var splashText: String? = nil
    @State private var splashTask: Task<Void, Never>? = nil

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
                if introPhase == .playing {
                    centerBox
                        .frame(width: boxSize, height: boxSize)
                        .rotationEffect(.degrees(dealerRotation))
                        .position(x: w / 2, y: h / 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                // Game Over overlay
                if showGameOverCard {
                    GameOverCard(session: session, isAutoEnd: gameOverIsAuto) {
                        let profileIDs = session.profileIDs
                        let ranked = session.players.enumerated()
                            .map { (index: $0.offset, player: $0.element) }
                            .sorted { $0.player.points > $1.player.points }
                        for (place, entry) in ranked.enumerated() {
                            guard entry.index < profileIDs.count,
                                  let profileID = profileIDs[entry.index] else { continue }
                            let descriptor = FetchDescriptor<UserProfile>(
                                predicate: #Predicate { $0.id == profileID }
                            )
                            if let profile = try? context.fetch(descriptor).first {
                                let result = GameResult(finalPoints: entry.player.points, placement: place + 1)
                                var results = profile.gameResults
                                results.append(result)
                                profile.gameResults = results
                            }
                        }
                        session.isActive = false
                        session.isPendingGameOver = false
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(20)
                }

                // Splash text overlay
                if let text = splashText {
                    SplashLabel(text: text)
                        .frame(maxWidth: w * 0.85)
                        .position(x: w / 2, y: h / 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .zIndex(15)
                }

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
                gameOverIsAuto = false
                withAnimation { showGameOverCard = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will end the current game. All scores are saved in history.")
        }
        .onChange(of: session.isPendingGameOver) { _, pending in
            if pending {
                gameOverIsAuto = true
                withAnimation { showGameOverCard = true }
            }
        }
        .onChange(of: session.roundLabel) { _, _ in
            guard introPhase == .playing, !session.isPendingGameOver else { return }
            showSplash("\(session.prevailingWind.label) Round \(session.dealerRotationCount + 1)")
        }
    }

    // MARK: - Intro Animation

    @MainActor
    private func runIntro(w: CGFloat, h: CGFloat) async {
        // --- Phase 1: Shuffle (≈3 s) ---
        showSplash("Shuffling Players", autoDismissAfter: nil)
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
        showSplash("Selecting the Dealer", autoDismissAfter: nil)
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
        clearSplash()

        // Show help tip after intro (first time only)
        if !hasSeenHelpTip {
            hasSeenHelpTip = true
            withAnimation { showHelpTip = true }
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation { showHelpTip = false }
        }
    }

    // MARK: - Splash helpers

    private func showSplash(_ text: String, autoDismissAfter seconds: Double? = 2.5) {
        splashTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) { splashText = text }
        guard let seconds else { return }
        splashTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) { splashText = nil }
        }
    }

    private func clearSplash() {
        splashTask?.cancel()
        splashTask = nil
        withAnimation(.easeIn(duration: 0.25)) { splashText = nil }
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
                        .frame(width: w, height: edgeHeight - 10)
                        .position(x: w / 2, y: h - edgeHeight / 2)
                case 1: // right
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: centerH, height: sideWidth - 5)
                        .rotationEffect(.degrees(-90))
                        .frame(width: sideWidth, height: centerH)
                        .position(x: w - sideWidth / 2, y: h / 2)
                case 2: // top
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: w, height: edgeHeight - 10)
                        .rotationEffect(.degrees(180))
                        .position(x: w / 2, y: edgeHeight / 2)
                case 3: // left
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(glow, lineWidth: 3)
                        .shadow(color: glow.opacity(0.7), radius: 10)
                        .frame(width: centerH, height: sideWidth - 5)
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
                isDealer: introPhase == .playing && session.dealerSeatIndex == playerIndex,
                onTap: { if introPhase == .playing { scoringForPlayer = playerIndex } }
            )
        }
    }

    // MARK: - Center box

    @ViewBuilder
    private var centerBox: some View {
        VStack(spacing: 10) {
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
        .padding(12)
        .background(MahjongTheme.centerCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
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

// MARK: - Splash Label

private struct SplashLabel: View {
    let text: String
    private let strokeWidth: CGFloat = 3

    private var strokeOffsets: [(CGFloat, CGFloat)] {
        let w = strokeWidth
        return [(-w,-w),(0,-w),(w,-w),(-w,0),(w,0),(-w,w),(0,w),(w,w)]
    }

    var body: some View {
        ZStack {
            ForEach(strokeOffsets.indices, id: \.self) { i in
                let (x, y) = strokeOffsets[i]
                Text(text)
                    .font(.system(size: 52, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .offset(x: x, y: y)
            }
            Text(text)
                .font(.system(size: 52, weight: .black))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
    }
}
