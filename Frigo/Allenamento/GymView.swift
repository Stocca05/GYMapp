import SwiftUI

enum GymTab: String, CaseIterable {
    case mieSchede = "Le Mie Schede", schede = "START", storico = "Storico"
}

struct GymView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    
    @State private var selectedTab: GymTab = .schede
    @State private var showCalendar = false
    
    // Gestione editor schede
    @State private var showCreator = false
    @State private var planToEdit: WorkoutPlan? = nil
    @State private var planToPlay: WorkoutPlan? = nil
    
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
        }
        .fullScreenCover(item: $planToEdit) { plan in
            WorkoutCreatorView(planToEdit: plan)
        }
        .fullScreenCover(item: $planToPlay) { plan in
            WorkoutActiveView()
                .onAppear {
                    if workoutManager.ongoingWorkout?.plan.id != plan.id {
                        workoutManager.startOrResumeWorkout(plan: plan)
                    }
                }
        }
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GymTab.allCases, id: \.self) { tab in
                    let isActive = selectedTab == tab
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .fixedSize(horizontal: true, vertical: false)
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
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder private var contentView: some View {
        if selectedTab == .storico {
            StoricoView()
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .schede:
                        startZone
                    case .mieSchede:
                        eserciziZone
                    case .storico:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Zone Content

    
    private var startZone: some View {
        VStack(spacing: 24) {
            // Il banner logico che abbiamo appena creato
            HeroWorkoutBanner()
            
            HStack(spacing: 16) {
                StreakWidgetView()
                CaloriesWidgetView()
            }
            .frame(height: 170)
            
            VolumeWidgetView()
            
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
                        WorkoutPlanCard(plan: plan, onEdit: { planToEdit = plan }, onPlay: { workoutManager.startOrResumeWorkout(plan: plan); planToPlay = plan })
                    }
                }
            }
        }
    }
}

#Preview { 
    GymView().environment(ThemeManager()) 
}
