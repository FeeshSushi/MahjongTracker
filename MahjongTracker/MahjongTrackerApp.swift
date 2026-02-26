import SwiftUI
import SwiftData

@main
struct MahjongTrackerApp: App {
    let sharedModelContainer: ModelContainer
    private let storageUnavailable: Bool
    @State private var showStorageAlert = false

    init() {
        let schema = Schema([GameSession.self, UserProfile.self])
        do {
            sharedModelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
            storageUnavailable = false
        } catch {
            // Persistent storage failed — fall back to in-memory so the app stays usable.
            // The .onAppear below will surface an alert to the user.
            sharedModelContainer = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
            storageUnavailable = true
        }
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
}

#Preview() {
    ContentView()
}
