import SwiftUI

@main
struct CinemaApp: App {
    @State private var store = CinemaApp.makeStore()
    @Environment(\.scenePhase) private var scenePhase

    /// Live services when the backend is configured in AppConfig, sample data otherwise.
    @MainActor
    static func makeStore() -> CinemaStore {
        guard let backend = SupabaseClient.shared else { return CinemaStore() }
        return CinemaStore(
            ideaEngine: LiveIdeaEngine(client: backend),
            editing: LiveAIEditingService(client: backend),
            payments: LivePaymentsService(client: backend),
            posting: LiveSocialPostingService(client: backend),
            coach: LiveCoachService(client: backend)
        )
    }

    init() {
        CinemaTips.configure()

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.surface)
        appearance.shadowColor = UIColor(Theme.stroke)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.backgroundColor = UIColor(Theme.background)
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.ink)]
        nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.ink)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.red)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { store.persist() }
                }
        }
    }
}
