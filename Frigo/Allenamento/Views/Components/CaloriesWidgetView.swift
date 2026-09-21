import SwiftUI

struct CaloriesWidgetView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    
    // Il goal potremmo renderlo configurabile, per ora fisso a 500 kcal
    let goal: Int = 500
    var calories: Int { workoutManager.caloriesBurnedToday }
    
    var progress: CGFloat {
        min(CGFloat(calories) / CGFloat(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.pink)
                    .font(.title2)
                Spacer()
            }
            .padding(.bottom, -8)
            
            ZStack {
                // Background Ring
                Circle()
                    .stroke(themeManager.currentTheme.secondaryColor.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Inner Text
                VStack(spacing: 2) {
                    Text("\(calories)")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(themeManager.currentTheme.textColor)
                    Text("kcal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.currentTheme.secondaryColor)
                }
            }
            .padding(8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    CaloriesWidgetView()
        .environment(ThemeManager())
        .frame(width: 170, height: 170)
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
