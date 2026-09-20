import SwiftUI

struct WorkoutPlanCard: View {
    @Environment(ThemeManager.self) private var themeManager
    let plan: WorkoutPlan
    
    var body: some View {
        HStack(spacing: 16) {
            textContent
            Spacer()
            playButton
        }
        .padding(16)
        .background(themeManager.currentTheme.primaryColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Subviews
extension WorkoutPlanCard {
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.title)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("\(plan.exercises.count) esercizi • ~\(plan.estimatedDurationInMinutes) min")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            Text(uniqueMusclesString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.primaryColor)
        }
    }
    
    private var playButton: some View {
        Image(systemName: "play.fill")
            .font(.title3)
            .foregroundColor(.white)
            .padding(14)
            .background(Circle().fill(themeManager.currentTheme.primaryColor))
            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.4), radius: 4, x: 0, y: 3)
    }
}

// MARK: - Helpers
extension WorkoutPlanCard {
    private var uniqueMusclesString: String {
        var unique: [String] = []
        for ex in plan.exercises {
            let label = ex.baseExercise.primaryMuscle.rawValue
            if !unique.contains(label) { unique.append(label) }
        }
        return unique.joined(separator: ", ")
    }
}

#Preview {
    let m1 = ExerciseModel(name: "Panca Piana", primaryMuscle: .chest)
    let w1 = WorkoutExercise(baseExercise: m1, sets: [WorkoutSet(targetReps: 10)])
    let plan = WorkoutPlan(title: "Forza Bruta", exercises: [w1])
    
    return WorkoutPlanCard(plan: plan)
        .padding()
        .environment(ThemeManager())
}
