import SwiftData
import SwiftUI

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var selectedProfile: UserProfile? = nil
    @State private var showingAddForm = false
    @State private var editingProfile: UserProfile? = nil

    private let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MahjongTheme.panelDark.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(
                        columns: columns,
                        spacing: MahjongTheme.Layout.gridSpacing
                    ) {
                        ForEach(profiles) { profile in
                            ProfileCard(profile: profile, isUsed: false)
                                .onTapGesture {
                                    selectedProfile = profile
                                }
                                .contextMenu {
                                    Button("Edit") { editingProfile = profile }
                                    Button("Delete", role: .destructive) {
                                        context.delete(profile)
                                    }
                                }
                        }
                        AddProfileCard { showingAddForm = true }
                    }
                    .padding()
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.feltDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MahjongTheme.primaryText)
                }
            }
            .sheet(item: $selectedProfile) { profile in
                ProfileResultsSheet(profile: profile)
            }
            .sheet(isPresented: $showingAddForm) {
                AddProfileView { emoji, name, colorHex in
                    context.insert(
                        UserProfile(
                            name: name,
                            emoji: emoji,
                            colorHex: colorHex
                        )
                    )
                }
            }
            .sheet(item: $editingProfile) { profile in
                EditProfileView(profile: profile)
            }
        }
    }
}

// MARK: - Profile Results Sheet

private struct ProfileResultsSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    private var sortedResults: [GameResult] {
        profile.gameResults.sorted { $0.datePlayed > $1.datePlayed }
    }

    private let placeLabels = ["🥇", "🥈", "🥉", "4️⃣"]
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if sortedResults.isEmpty {
                    ContentUnavailableView(
                        "No Games Played",
                        systemImage: "gamecontroller",
                        description: Text(
                            "Results will appear here after \(profile.name) plays a game."
                        )
                    )
                } else {
                    List(sortedResults) { result in
                        HStack(spacing: 12) {
                            Text(placeLabels[min(result.placement - 1, 3)])
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(result.finalPoints) pts")
                                    .font(
                                        .body.monospacedDigit().weight(
                                            .semibold
                                        )
                                    )
                                    .foregroundColor(MahjongTheme.primaryText)
                                Text(
                                    dateFormatter.string(
                                        from: result.datePlayed
                                    )
                                )
                                .font(.caption)
                                .foregroundColor(MahjongTheme.secondaryText)
                            }

                            Spacer()

                            Text(placeName(result.placement))
                                .font(.caption.bold())
                                .foregroundColor(MahjongTheme.secondaryText)
                        }
                        .listRowBackground(MahjongTheme.tileBackground)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowSeparatorTint(Color.white.opacity(0.10))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MahjongTheme.feltDark)
            .navigationTitle(
                "\(profile.emoji.isEmpty ? "" : profile.emoji + " ")\(profile.name)"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.feltDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(MahjongTheme.primaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func placeName(_ placement: Int) -> String {
        switch placement {
        case 1: return String(localized: "1st")
        case 2: return String(localized: "2nd")
        case 3: return String(localized: "3rd")
        default: return String(localized: "4th")
        }
    }
}
