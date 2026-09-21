import SwiftUI
import Charts

struct VolumeWidgetView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    
    var recentData: [WorkoutManager.HistoricalVolume] {
        workoutManager.getRecentVolumes()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tonnellaggio")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeManager.currentTheme.secondaryColor)
                    
                    Text("Ultimi Allenamenti")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(themeManager.currentTheme.textColor)
                }
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                    .font(.title2)
            }
            
            if recentData.isEmpty {
                VStack {
                    Spacer()
                    Text("Nessun dato")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.currentTheme.secondaryColor)
                    Spacer()
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                Chart(recentData) { item in
                    BarMark(
                        x: .value("Sessione", item.sessionName),
                        y: .value("Volume (kg)", item.volume)
                    )
                    .foregroundStyle(themeManager.currentTheme.primaryColor.opacity(0.8))
                    .cornerRadius(6)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(themeManager.currentTheme.secondaryColor)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 120)
                .padding(.top, 8)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VolumeWidgetView()
        .environment(ThemeManager())
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
