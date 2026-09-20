import SwiftUI

enum GymTab: String, CaseIterable {
    case esercizi = "Esercizi", schede = "START", storico = "Storico"
}

struct GymView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var workoutManager = WorkoutManager()
    @State private var selectedTab: GymTab = .schede
    @State private var showCalendar = false
    
    // Per creare una NUOVA scheda
    @State private var showCreator = false
    // Per MODIFICARE una scheda esistente
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
        // NUOVO: Apriamo la form precompilata quando premiamo su una scheda
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
            Text("Gym").font(.system(.largeTitle, design: .serif)).italic().bold().foregroundStyle(themeManager.currentTheme.textColor)
            Spacer()
            Button(action: { showCalendar = true }) {
                Image(systemName: "calendar").font(.title2).foregroundStyle(themeManager.currentTheme.primaryColor)
            }
        }
        .padding(.horizontal).padding(.top, 8).padding(.bottom, 16)
    }
    
    private var pickerView: some View {
        HStack(spacing: 8) {
            ForEach(GymTab.allCases, id: \.self) { tab in
                let isActive = selectedTab == tab
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                    Text(tab.rawValue)
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .foregroundStyle(isActive ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
                        .background(Capsule().fill(isActive ? themeManager.currentTheme.primaryColor : .clear))
                }
            }
        }
        .padding(.horizontal).padding(.bottom, 16)
    }
    
    @ViewBuilder private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch selectedTab {
                case .schede: schedeZone
                case .esercizi: eserciziZone
                case .storico: storicoZone
                }
            }
            .padding(.horizontal).padding(.top, 8).padding(.bottom, 32)
        }
    }
    
    // MARK: - Zone Content
    
    private var schedeZone: some View { VStack(spacing: 16) {} }
    
    @ViewBuilder
    private var eserciziZone: some View {
        VStack(spacing: 16) {
            
            Button(action: {
                showCreator = true
            }) {
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
                        // Il tap apre la scheda in modalità modifica, senza toccare il bottone play interno
                        WorkoutPlanCard(plan: plan)
                            .onTapGesture {
                                planToEdit = plan
                            }
                    }
                }
            }
        }
    }
    
    private var storicoZone: some View { VStack(spacing: 16) {} }
}

#Preview { 
    GymView().environment(ThemeManager()) 
}
