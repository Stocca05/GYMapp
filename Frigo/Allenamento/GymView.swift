import SwiftUI

enum GymTab: String, CaseIterable {
    case esercizi = "Le Mie Schede", schede = "START", storico = "Storico"
}

struct GymView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var workoutManager = WorkoutManager()
    
    @State private var selectedTab: GymTab = .schede
    @State private var showCalendar = false
    
    // Gestione editor schede
    @State private var showCreator = false
    @State private var planToEdit: WorkoutPlan? = nil
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                pickerView
                contentView
            }
        }
        .sheet(isPresented: $showCalendar) { GymCalendarView() }
        .fullScreenCover(isPresented: $showCreator) { 
            WorkoutCreatorView()
                .environment(workoutManager)
                .environment(themeManager) 
        }
        .fullScreenCover(item: $planToEdit) { plan in
            WorkoutCreatorView(planToEdit: plan)
                .environment(workoutManager)
                .environment(themeManager)
        }
        .environment(workoutManager)
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        HStack {
            Text("Gym")
                .font(.system(.largeTitle, design: .serif))
                .italic()
                .bold()
                .foregroundStyle(themeManager.currentTheme.textColor)
            Spacer()
            Button(action: { showCalendar = true }) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var pickerView: some View {
        HStack(spacing: 8) {
            ForEach(GymTab.allCases, id: \.self) { tab in
                let isActive = selectedTab == tab
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .foregroundStyle(isActive ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
                        .background(Capsule().fill(isActive ? themeManager.currentTheme.primaryColor : .clear))
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch selectedTab {
                case .schede: 
                    // Il nostro fantastico banner dinamico!
                    startZone
                case .esercizi: 
                    eserciziZone
                case .storico: 
                    // TODO: Implementare Storico
                    Text("Storico Allenamenti (Coming Soon)")
                        .padding(.top, 40)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Zone Content

    @ViewBuilder
    private var startZone: some View {
        VStack(spacing: 24) {
            // Il banner logico che abbiamo appena creato
            HeroWorkoutBanner()
            
            // Qui in futuro metteremo gli altri moduli (Calorie e Streak)
            // ...
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var eserciziZone: some View {
        VStack(spacing: 16) {
            Button(action: { showCreator = true }) {
                Label("Crea Nuova Scheda", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.primaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.bottom, 8)
            
            LazyVStack(spacing: 16) {
                if workoutManager.myPlans.isEmpty {
                    Text("Non hai ancora creato schede.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                        .padding(.top, 24)
                } else {
                    ForEach(workoutManager.myPlans) { plan in
                        WorkoutPlanCard(plan: plan)
                            .onTapGesture {
                                planToEdit = plan
                            }
                    }
                }
            }
        }
    }
}

#Preview { 
    GymView().environment(ThemeManager()) 
}
