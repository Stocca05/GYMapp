import SwiftUI
import HealthKit

@main struct MyApp: App {
    @AppStorage("darkModeOverride") private var darkModeOverride = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var themeManager = ThemeManager()
    @State private var workoutManager = WorkoutManager()
    @State private var healthManager = HealthManager()

    init() {
        WorkoutNotificationManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkModeOverride ? .dark : nil)
                .environment(themeManager)
                .environment(workoutManager)
                .environment(healthManager)
                .task {
                    await healthManager.requestAuthorization()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { healthManager.refreshAuthorization() }
                }
        }
    }
}
