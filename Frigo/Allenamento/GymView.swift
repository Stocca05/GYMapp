import SwiftUI

enum GymTab: String, CaseIterable {
    case esercizi = "Esercizi", schede = "START", storico = "Storico"
}

struct GymView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab: GymTab = .schede
    @State private var showCalendar = false
    
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
    
    private var eserciziZone: some View { VStack(spacing: 16) {} }
    
    private var storicoZone: some View { VStack(spacing: 16) {} }
}

#Preview { GymView().environment(ThemeManager()) }
