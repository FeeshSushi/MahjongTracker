import SwiftUI
import SwiftData

@main
struct MahjongTrackerApp: App {
    let sharedModelContainer: ModelContainer
    private let storageUnavailable: Bool
    @State private var showStorageAlert = false

    init() {
        let schema = Schema([
            GameSession.self,
            UserProfile.self,
            PlayerRecord.self,
            ScoreRecord.self,
            GameResultRecord.self
        ])
        var unavailable = false
        do {
            sharedModelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            // Persistent storage failed — fall back to in-memory so the app stays usable.
            do {
                sharedModelContainer = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
                unavailable = true
            } catch {
                fatalError("ModelContainer creation failed entirely: \(error)")
            }
        }
        storageUnavailable = unavailable
        performWipeIfNeeded(container: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if storageUnavailable { showStorageAlert = true }
                }
                .alert("Storage Unavailable", isPresented: $showStorageAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your game data couldn't be saved to disk. Games will work normally this session, but scores won't persist when you close the app.")
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func performWipeIfNeeded(container: ModelContainer) {
        let stored = UserDefaults.standard.integer(forKey: AppStorageKeys.schemaVersion)
        guard stored < currentSchemaVersion else { return }
        let ctx = container.mainContext
        // Cascade delete rules propagate to children; delete parents only.
        try? ctx.delete(model: GameSession.self)
        try? ctx.delete(model: UserProfile.self)
        try? ctx.save()
        UserDefaults.standard.set(currentSchemaVersion, forKey: AppStorageKeys.schemaVersion)
    }
}

#Preview() {
    ContentView()
}
