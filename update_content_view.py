import re

with open("Frigo/ContentView.swift", "r") as f:
    text = f.read()

# Add `@State private var showActiveWorkout = false`
state_decl = """    @Environment(WorkoutManager.self) private var workoutManager
    
    // Variabile che tiene traccia della scheda aperta (0, 1 o 2).
    @State private var selectedTab = 1
    
    // Variabile per mostrare l'allenamento in corso in full screen
    @State private var showActiveWorkout = false
"""
text = re.sub(r'    // Variabile che tiene traccia della scheda aperta.*?@State private var selectedTab = 1.*?\n', state_decl, text, flags=re.DOTALL)

# Add mini player and fullScreenCover
mini_player_ui = """            // MARK: - COMPONENTE TAB BAR CUSTOM
            VStack(spacing: 0) {
                if workoutManager.ongoingWorkout != nil {
                    miniWorkoutPlayer
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                customTabBar
            }
"""
text = text.replace('            // MARK: - COMPONENTE TAB BAR CUSTOM\n            customTabBar', mini_player_ui)


full_screen_cover = """        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            WorkoutActiveView()
        }
"""
text = text.replace('        .ignoresSafeArea(.keyboard)\n', full_screen_cover)

# Add the miniWorkoutPlayer view
mini_player = """    
    // MARK: - MINI WORKOUT PLAYER (IN-APP BANNER)
    private var miniWorkoutPlayer: some View {
        Button(action: {
            showActiveWorkout = true
        }) {
            HStack(spacing: 12) {
                // Icona animata
                Image(systemName: workoutManager.ongoingWorkout!.isResting ? "timer" : "flame.fill")
                    .foregroundColor(workoutManager.ongoingWorkout!.isResting ? .orange : .white)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutManager.ongoingWorkout!.plan.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if workoutManager.ongoingWorkout!.isResting {
                        Text("Recupero in corso...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Esercizio in corso")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.up")
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(workoutManager.ongoingWorkout!.isResting ? 1.0 : 0.0))
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeManager.currentTheme.primaryColor)
                            .opacity(workoutManager.ongoingWorkout!.isResting ? 0 : 1)
                    )
                    .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }
"""

text = text.replace("    private var customTabBar: some View {", mini_player + "\n    private var customTabBar: some View {")


with open("Frigo/ContentView.swift", "w") as f:
    f.write(text)

