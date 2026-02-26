import SwiftUI
import SwiftData

struct ProfilePickerSheet: View {
    let slotLabel: String
    let usedProfileIDs: Set<UUID>
    var onSelect: (UserProfile) -> Void
    var onClear: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showingAddForm = false
    @State private var editingProfile: UserProfile? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                MahjongTheme.panelDark.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: MahjongTheme.Layout.gridSpacing) {
                        ForEach(profiles) { profile in
                            let isUsed = usedProfileIDs.contains(profile.id)
                            ProfileCard(profile: profile, isUsed: isUsed)
                                .onTapGesture {
                                    guard !isUsed else { return }
                                    onSelect(profile)
                                    dismiss()
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        editingProfile = profile
                                    }
                                    Button("Delete", role: .destructive) {
                                        context.delete(profile)
                                    }
                                }
                        }
                        AddProfileCard {
                            showingAddForm = true
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(slotLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.panelDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MahjongTheme.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") { onClear(); dismiss() }
                        .foregroundStyle(MahjongTheme.primaryText)
                }
            }
            .sheet(isPresented: $showingAddForm) {
                AddProfileView { emoji, name, colorHex in
                    let profile = UserProfile(name: name, emoji: emoji, colorHex: colorHex)
                    context.insert(profile)
                }
            }
            .sheet(item: $editingProfile) { profile in
                EditProfileView(profile: profile)
            }
        }
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: UserProfile
    let isUsed: Bool

    var profileColor: Color { Color(hex: profile.colorHex) }

    var body: some View {
        VStack(spacing: 6) {
            Text(profile.emoji.isEmpty ? "👤" : profile.emoji)
                .font(.largeTitle)
            Text(profile.name)
                .font(.caption.bold())
                .foregroundColor(MahjongTheme.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MahjongTheme.tileBackground)
        .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.profileCard))
        .overlay(
            RoundedRectangle(cornerRadius: MahjongTheme.Radius.profileCard)
                .strokeBorder(profileColor, lineWidth: MahjongTheme.Layout.profileBorderWidth)
        )
        .opacity(isUsed ? MahjongTheme.Opacity.profileDimmed : 1)
    }
}

// MARK: - Add Profile Card

struct AddProfileCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(MahjongTheme.secondaryText)
                Text("New")
                    .font(.caption.bold())
                    .foregroundColor(MahjongTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(MahjongTheme.tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: MahjongTheme.Radius.profileCard))
            .overlay(
                RoundedRectangle(cornerRadius: MahjongTheme.Radius.profileCard)
                    .strokeBorder(style: StrokeStyle(lineWidth: MahjongTheme.Layout.tileBorderWidth, dash: MahjongTheme.Layout.addCardDash))
                    .foregroundColor(MahjongTheme.secondaryText.opacity(MahjongTheme.Opacity.dashBorder))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Profile Form

struct AddProfileView: View {
    var onCreate: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var emoji = ""
    @State private var name = ""
    @State private var selectedColor: Color = Color(hex: "#5E8CF0")

    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    TextField("e.g. 🐯", text: $emoji)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(MahjongTheme.primaryText)
                        .onChange(of: emoji) { _, new in
                            let trimmed = String(new.prefix(1))
                            if emoji != trimmed { emoji = trimmed }
                        }
                }
                .listRowBackground(MahjongTheme.tileBackground)
                Section("Name") {
                    TextField("Username", text: $name)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)
                Section("Color") {
                    ColorPicker("Profile Color", selection: $selectedColor, supportsOpacity: false)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)
            }
            .scrollContentBackground(.hidden)
            .background(MahjongTheme.panelDark)
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.panelDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MahjongTheme.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onCreate(emoji, name, selectedColor.toHex())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(MahjongTheme.primaryText)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Profile Form

struct EditProfileView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var emoji: String = ""
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue

    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    TextField("e.g. 🐯", text: $emoji)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(MahjongTheme.primaryText)
                        .onChange(of: emoji) { _, new in
                            let trimmed = String(new.prefix(1))
                            if emoji != trimmed { emoji = trimmed }
                        }
                }
                .listRowBackground(MahjongTheme.tileBackground)
                Section("Name") {
                    TextField("Username", text: $name)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)
                Section("Color") {
                    ColorPicker("Profile Color", selection: $selectedColor, supportsOpacity: false)
                        .foregroundColor(MahjongTheme.primaryText)
                }
                .listRowBackground(MahjongTheme.tileBackground)
            }
            .scrollContentBackground(.hidden)
            .background(MahjongTheme.panelDark)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MahjongTheme.panelDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MahjongTheme.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.emoji = emoji
                        profile.name = name
                        profile.colorHex = selectedColor.toHex()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(MahjongTheme.primaryText)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            emoji = profile.emoji
            name = profile.name
            selectedColor = Color(hex: profile.colorHex)
        }
    }
}
