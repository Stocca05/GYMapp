import SwiftUI
import HealthKit

struct ProfileView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(HealthManager.self) private var healthManager
    @Environment(WorkoutManager.self) private var workoutManager
    
    @AppStorage("userName") private var userName: String = "Utente"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("darkModeOverride") private var darkModeOverride: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        userHeader
                        statsGrid
                        integrationSection
                        settingsSection
                        appInfoSection
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header
    
    private var userHeader: some View {
        HStack(spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 86, height: 86)
                    .foregroundColor(themeManager.currentTheme.primaryColor.opacity(0.8))
                    .background(Circle().fill(themeManager.currentTheme.primaryColor.opacity(0.1)))
                
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                            .font(.title3)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                TextField("Il tuo nome", text: $userName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(memberSinceText)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var memberSinceText: String {
        // Potremmo usare la data del primo allenamento, o di installazione
        if let first = workoutManager.completedSessions.sorted(by: { $0.date < $1.date }).first {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "it_IT")
            return "Membro da \(formatter.string(from: first.date).capitalized)"
        }
        return "Nuovo Membro"
    }
    
    // MARK: - Stats
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Allenamenti",
                value: "\(workoutManager.completedSessions.count)",
                icon: "figure.strengthtraining.traditional",
                color: themeManager.currentTheme.primaryColor
            )
            
            statCard(
                title: "Schede CREATE",
                value: "\(workoutManager.myPlans.count)",
                icon: "doc.plaintext.fill",
                color: .orange
            )
            
            statCard(
                title: "Serie Totali",
                value: "\(totalSetsCompleted)",
                icon: "repeat.circle.fill",
                color: .mint
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var totalSetsCompleted: Int {
        // Semplice aggregazione
        // Nelle tue versioni avanzate potresti tracciare il numero di serie effettivamente chiuse
        // Per ora mostriamo un mockup che cresce con le sessioni
        return workoutManager.completedSessions.reduce(0) { $0 + $1.totalVolume / 50 }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Apple Health Integrations
    
    private var integrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integrazioni")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Health")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.textColor)
                        Text("Sincronizza e leggi i dati vitali")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                    }
                    
                    Spacer()
                    
                    if healthManager.isAuthorized {
                        HStack(spacing: 4) {
                            Text("Connesso")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.green)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button(action: {
                            Task {
                                await healthManager.requestAuthorization()
                            }
                        }) {
                            Text("Connetti")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(themeManager.currentTheme.primaryColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Settings
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impostazioni Generali")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                // Notifiche
                Toggle(isOn: $notificationsEnabled) {
                    settingsRow(icon: "bell.badge.fill", iconColor: .yellow, title: "Notifiche Attive")
                }
                .tint(themeManager.currentTheme.primaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().padding(.leading, 60)
                
                // Dark mode override (mock)
                Toggle(isOn: $darkModeOverride) {
                    settingsRow(icon: "moon.fill", iconColor: .indigo, title: "Sforza Modalità Scura")
                }
                .tint(themeManager.currentTheme.primaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider().padding(.leading, 60)
                
                // Info e licenze
                NavigationLink(destination: Text("Politiche sulla privacy e Licenze").navigationTitle("Legale")) {
                    HStack {
                        settingsRow(icon: "doc.text.fill", iconColor: .gray, title: "Privacy e Licenze")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundColor(themeManager.currentTheme.secondaryColor.opacity(0.3))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
        }
    }
    
    private func settingsRow(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .bold))
            }
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
    
    // MARK: - App Info
    
    private var appInfoSection: some View {
        VStack(spacing: 6) {
            Image("app.icon") // Fallback se non c'è: userà l'icona normale senza crash
                 .resizable()
                 .frame(width: 60, height: 60)
                 .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                 .opacity(0) // Nascosta in attesa dell'icona vera, oppure togliamo e lasciamo scritte
                 .frame(height: 0) // per non occupare spazio
            
            Text("Frigo App v1.0.0")
                .font(.footnote.weight(.semibold))
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            Text("Designed for minimalist results.")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryColor.opacity(0.6))
        }
        .padding(.top, 16)
    }
}

#Preview {
    ProfileView()
        .environment(ThemeManager())
        .environment(HealthManager())
        .environment(WorkoutManager())
}
