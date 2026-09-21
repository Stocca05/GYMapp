import SwiftUI

@main struct MyApp: App {
    @State private var themeManager = ThemeManager()
    @State private var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(workoutManager)
        }
    }
}
