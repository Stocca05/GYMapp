import SwiftUI

struct StreakWidgetView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(HealthManager.self) private var healthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(healthManager.workoutStreak) Allenam.")
                    .font(.system(.title3, design: .rounded, weight: .heavy)).minimumScaleFactor(0.8).lineLimit(1)
                    .foregroundStyle(themeManager.currentTheme.textColor)
                Text("Costanza")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                let weekStatus = healthManager.getWeekStatus()
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(weekStatus[index] ? .orange : themeManager.currentTheme.secondaryColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StreakWidgetView()
        .environment(ThemeManager())
        .environment(HealthManager())
        .frame(width: 170, height: 170)
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
