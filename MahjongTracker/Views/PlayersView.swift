import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var selectedProfile: UserProfile? = nil
    @State private var showingAddForm = false
    @State private var editingProfile: UserProfile? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(profiles) { profile in
                        ProfileCard(profile: profile, isUsed: false)
                            .onTapGesture {
                                selectedProfile = profile
                            }
                            .contextMenu {
                                Button("Edit") { editingProfile = profile }
                                Button("Delete", role: .destructive) { context.delete(profile) }
                            }
                    }
                    AddProfileCard { showingAddForm = true }
                }
                .padding()
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedProfile) { profile in
                ProfileResultsSheet(profile: profile)
            }
            .sheet(isPresented: $showingAddForm) {
                AddProfileView { emoji, name, colorHex in
                    context.insert(UserProfile(name: name, emoji: emoji, colorHex: colorHex))
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
                        description: Text("Results will appear here after \(profile.name) plays a game.")
                    )
                } else {
                    List(sortedResults) { result in
                        HStack(spacing: 12) {
                            Text(placeLabels[min(result.placement - 1, 3)])
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(result.finalPoints) pts")
                                    .font(.body.monospacedDigit().weight(.semibold))
                                Text(dateFormatter.string(from: result.datePlayed))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(placeName(result.placement))
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("\(profile.emoji.isEmpty ? "" : profile.emoji + " ")\(profile.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func placeName(_ placement: Int) -> String {
        switch placement {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "4th"
        }
    }
}
