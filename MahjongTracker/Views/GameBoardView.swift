import SwiftUI
import SwiftData
import OSLog

// Allows using Int as the item type for .sheet(item:)
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MahjongTracker", category: "GameSession")

struct GameBoardView: View {
    @Bindable var session: GameSession
    @Environment(\.modelContext) private var context

    @State private var scoringForPlayer: Int? = nil  // seatIndex
    @State private var showManualAdjust = false
    @State private var showHistory = false
    @State private var showHandRef = false
    @State private var showEndGameAlert = false
    @State private var showGameOverCard = false
    @State private var gameOverIsAuto = false
    @State private var showFoulHand = false
    @State private var showDrawOutAlert = false

    // Help tip
    @State private var showHelpTip = false
    @AppStorage(AppStorageKeys.hasSeenHelpTip) private var hasSeenHelpTip = false
    @State private var helpTask: Task<Void, Never>? = nil

    // Intro animation
    private enum IntroPhase { case shuffling, dealerSpin, playing }
    @State private var introPhase: IntroPhase = .playing
    @State private var displayOrder: [Int] = [0, 1, 2, 3]  // visual slot → seatIndex
    @State private var highlightedSlot: Int? = nil

    // Splash text overlay
    @State private var splashText: String? = nil
    @State private var splashTask: Task<Void, Never>? = nil

    private let sideWidth: CGFloat = MahjongTheme.Layout.sideWidth
    private let edgeHeight: CGFloat = MahjongTheme.Layout.edgeHeight

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
                    CenterBoxView(
                        prevailingWind: session.prevailingWind,
                        dealerRotationCount: session.dealerRotationCount,
                        honba: session.honba,
                        showHandRef: $showHandRef,
                        showEndGameAlert: $showEndGameAlert,
                        showHistory: $showHistory,
                        showManualAdjust: $showManualAdjust,
                        showFoulHand: $showFoulHand,
                        showDrawOutAlert: $showDrawOutAlert,
                        onHelpTap: showHelpTipWithAutoDismiss
                    )
                    .frame(width: boxSize, height: boxSize)
                    .rotationEffect(.degrees(dealerRotation))
                    .position(x: w / 2, y: h / 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                // Game Over overlay
                if showGameOverCard {
                    GameOverCard(session: session, isAutoEnd: gameOverIsAuto) {
                        finalizeGame()
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
                    .frame(maxWidth: MahjongTheme.Layout.tooltipMaxWidth)
                    .position(x: w / 2, y: h - edgeHeight - 60)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
                    .zIndex(10)
                }
            }
            .task {
                // Single consolidated task — SwiftUI auto-cancels on view disappear
                guard !session.introCompleted else {
                    if !hasSeenHelpTip {
                        hasSeenHelpTip = true
                        withAnimation { showHelpTip = true }
                        try? await Task.sleep(for: .seconds(MahjongTheme.Timing.helpAutoDismiss))
                        withAnimation { showHelpTip = false }
                    }
                    return
                }
                introPhase = .shuffling
                await runIntro(w: w, h: h)
            }
        }
        .padding(.horizontal, 2)
        .background(MahjongTheme.feltDark)
        .ignoresSafeArea(edges: .horizontal)
        .onDisappear {
            splashTask?.cancel()
            helpTask?.cancel()
        }
        .sheet(item: $scoringForPlayer) { seatIndex in
            ScoringSheetView(session: session, preselectWinnerSeatIndex: seatIndex)
        }
        .sheet(isPresented: $showManualAdjust) {
            ManualAdjustView(session: session)
        }
        .sheet(isPresented: $showFoulHand) {
            FoulHandView(session: session)
        }
        .alert("Draw Out?", isPresented: $showDrawOutAlert) {
            Button("Confirm", role: .destructive) { applyDrawOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("No winner this round. Dealer stays and honba increments.")
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

    // MARK: - Game End

    @MainActor
    private func finalizeGame() {
        let profileIDs = session.profileIDs  // [UUID?] indexed by seatIndex
        let ranked = session.players.sorted { $0.points > $1.points }
        do {
            for (place, player) in ranked.enumerated() {
                guard player.seatIndex < profileIDs.count,
                      let pid = profileIDs[player.seatIndex] else { continue }
                let descriptor = FetchDescriptor<UserProfile>(
                    predicate: #Predicate { $0.id == pid }
                )
                if let profile = try context.fetch(descriptor).first {
                    profile.gameResults.append(
                        GameResultRecord(finalPoints: player.points, placement: place + 1)
                    )
                }
            }
            session.isActive = false
            session.isPendingGameOver = false
            try context.save()
        } catch {
            logger.error("Failed to save game results: \(error)")
            session.isActive = false
            session.isPendingGameOver = false
        }
    }

    // MARK: - Draw Out

    private func applyDrawOut() {
        let record = ScoreRecord(
            prevailingWind: session.prevailingWind,
            dealerSeatIndex: session.dealerSeatIndex,
            honba: session.honba,
            winType: .drawOut,
            winnerSeatIndex: nil,
            discarderSeatIndex: nil,
            fan: 0,
            deltas: [0, 0, 0, 0],
            summary: ScoringEngine.summaryString(
                winnerName: "",
                winType: .drawOut,
                fan: 0,
                discarderName: nil,
                winnerDelta: 0
            )
        )
        session.applyDrawOut(record: record)
        showSplash("Draw Out")
    }

    // MARK: - Help tip

    private func showHelpTipWithAutoDismiss() {
        helpTask?.cancel()
        withAnimation { showHelpTip = true }
        helpTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(MahjongTheme.Timing.helpAutoDismiss))
            guard !Task.isCancelled else { return }
            withAnimation { showHelpTip = false }
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

        // Update seatIndex values on PlayerRecord objects to match final display arrangement.
        // finalOrder[slot] = original seatIndex of player who should visually occupy slot.
        let snapshot = session.players
        for (slot, originalSeatIndex) in finalOrder.enumerated() {
            if let player = snapshot.first(where: { $0.seatIndex == originalSeatIndex }) {
                player.seatIndex = slot
            }
        }
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
            withAnimation(.easeInOut(duration: MahjongTheme.Timing.spinStep)) { highlightedSlot = slot }
            try? await Task.sleep(for: .seconds(delay))
        }

        withAnimation {
            highlightedSlot = finalDealer
            session.dealerSeatIndex = finalDealer
        }
        try? await Task.sleep(for: .seconds(MahjongTheme.Timing.selectionPause))

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
        withAnimation(.easeOut(duration: MahjongTheme.Timing.splashFade)) { splashText = text }
        guard let seconds else { return }
        splashTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: MahjongTheme.Timing.splashFade)) { splashText = nil }
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
                    RoundedRectangle(cornerRadius: MahjongTheme.Radius.tile)
                        .stroke(glow, lineWidth: MahjongTheme.Layout.dealerStrokeWidth)
                        .shadow(color: glow.opacity(MahjongTheme.Opacity.dealerGlow), radius: MahjongTheme.Layout.dealerGlowRadius)
                        .frame(width: w, height: edgeHeight - 10)
                        .position(x: w / 2, y: h - edgeHeight / 2)
                case 1: // right
                    RoundedRectangle(cornerRadius: MahjongTheme.Radius.tile)
                        .stroke(glow, lineWidth: MahjongTheme.Layout.dealerStrokeWidth)
                        .shadow(color: glow.opacity(MahjongTheme.Opacity.dealerGlow), radius: MahjongTheme.Layout.dealerGlowRadius)
                        .frame(width: centerH, height: sideWidth - 5)
                        .rotationEffect(.degrees(-90))
                        .frame(width: sideWidth, height: centerH)
                        .position(x: w - sideWidth / 2, y: h / 2)
                case 2: // top
                    RoundedRectangle(cornerRadius: MahjongTheme.Radius.tile)
                        .stroke(glow, lineWidth: MahjongTheme.Layout.dealerStrokeWidth)
                        .shadow(color: glow.opacity(MahjongTheme.Opacity.dealerGlow), radius: MahjongTheme.Layout.dealerGlowRadius)
                        .frame(width: w, height: edgeHeight - 10)
                        .rotationEffect(.degrees(180))
                        .position(x: w / 2, y: edgeHeight / 2)
                case 3: // left
                    RoundedRectangle(cornerRadius: MahjongTheme.Radius.tile)
                        .stroke(glow, lineWidth: MahjongTheme.Layout.dealerStrokeWidth)
                        .shadow(color: glow.opacity(MahjongTheme.Opacity.dealerGlow), radius: MahjongTheme.Layout.dealerGlowRadius)
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
    private func tile(for seatIndex: Int) -> some View {
        if let player = session.player(atSeat: seatIndex) {
            PlayerTileView(
                player: player,
                seatWind: session.seatWind(forSeat: seatIndex),
                isDealer: introPhase == .playing && session.dealerSeatIndex == seatIndex,
                onTap: { if introPhase == .playing { scoringForPlayer = seatIndex } }
            )
        }
    }
}

// MARK: - Center Box View

private struct CenterBoxView: View {
    let prevailingWind: Wind
    let dealerRotationCount: Int
    let honba: Int
    @Binding var showHandRef: Bool
    @Binding var showEndGameAlert: Bool
    @Binding var showHistory: Bool
    @Binding var showManualAdjust: Bool
    @Binding var showFoulHand: Bool
    @Binding var showDrawOutAlert: Bool
    var onHelpTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 3) {
                Text(prevailingWind.character)
                    .font(MahjongTheme.Font.windCharacter)
                    .foregroundColor(MahjongTheme.primaryText)
                Text("\(prevailingWind.label) Round \(dealerRotationCount + 1)")
                    .font(.caption)
                    .foregroundColor(MahjongTheme.secondaryText)
                if honba > 0 {
                    Text("本 \(honba)")
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
                Button {
                    showFoulHand = true
                } label: {
                    Label("False Win", systemImage: "xmark.circle")
                }
                Button {
                    showDrawOutAlert = true
                } label: {
                    Label("Draw Out", systemImage: "arrow.trianglehead.clockwise")
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
        .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.centerBox))
        .overlay(alignment: .topTrailing) {
            Button {
                onHelpTap()
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.caption)
                    .foregroundColor(MahjongTheme.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: MahjongTheme.Radius.centerBox)
                .stroke(Color.white.opacity(MahjongTheme.Opacity.overlayStroke), lineWidth: 1)
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
                    .font(MahjongTheme.Font.splashHero)
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
