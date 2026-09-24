import SwiftUI

struct MuscleHeatmapView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Affaticamento Muscolare (Ultime 72h)")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            let volumes = recentMuscleVolumes()
            let maxVolume = volumes.values.max() ?? 1
            
            // Simple visual representation of muscle groups
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    if muscle != .cardio && muscle != .fullBody {
                        let volume = volumes[muscle] ?? 0
                        let intensity = volume > 0 ? (volume / maxVolume) : 0
                        
                        VStack {
                            Image(systemName: muscle.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(colorForIntensity(intensity))
                            
                            Text(muscle.rawValue)
                                .font(.caption2.bold())
                                .foregroundColor(.primary)
                            
                            if volume > 0 {
                                Text("\(Int(volume)) kg")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(colorForIntensity(intensity).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        // Visual border based on fatigue
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorForIntensity(intensity).opacity(intensity > 0 ? 0.3 : 0.0), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private func recentMuscleVolumes() -> [MuscleGroup: Double] {
        let cutoff = Date().addingTimeInterval(-72 * 3600)
        let recentSessions = workoutManager.completedSessions.filter { $0.date >= cutoff }
        
        var volumes: [MuscleGroup: Double] = [:]
        
        for session in recentSessions {
            for exercise in session.completedExercises {
                let muscle = exercise.baseExercise.primaryMuscle
                let exVolume = exercise.sets.filter { $0.setType != .warmup }.reduce(0.0) { sum, set in
                    sum + (set.targetWeight ?? 0) * Double(set.targetReps)
                }
                volumes[muscle, default: 0] += exVolume
            }
        }
        
        return volumes
    }
    
    private func colorForIntensity(_ intensity: Double) -> Color {
        if intensity == 0 { return .gray.opacity(0.5) }
        if intensity < 0.3 { return .green }
        if intensity < 0.7 { return .orange }
        return .red
    }
}

#Preview {
    MuscleHeatmapView()
        .environment(WorkoutManager())
        .environment(ThemeManager())
}
