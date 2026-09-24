import SwiftUI
import HealthKit

@main struct MyApp: App {
    @State private var themeManager = ThemeManager()
    @State private var workoutManager = WorkoutManager()
    @State private var healthManager = HealthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(workoutManager)
                .environment(healthManager)
                .task {
                    await healthManager.requestAuthorization()
                }
        }
    }
}
