import Foundation
import HealthKit

@Observable
@MainActor
class HealthManager {
    let healthStore = HKHealthStore()
    
    // Authorization state
    var isAuthorized: Bool = false
    
    // Cached values for UI
    var caloriesBurnedToday: Int = 0
    var workoutStreak: Int = 0
    
    // All workout dates to properly compute streak
    var workoutDates: Set<Date> = []
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let typesToShare: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            self.isAuthorized = true
            await fetchTodayCalories()
            await fetchWorkoutsAndCalculateStreak()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }
    
    func fetchTodayCalories() async {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let sum = result?.sumQuantity(), error == nil else {
                return
            }
            
            let calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
            Task { @MainActor in
                self.caloriesBurnedToday = calories
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchWorkoutsAndCalculateStreak() async {
        let workoutType = HKObjectType.workoutType()
        
        // Fetch last 365 days of workouts
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            guard let workouts = results as? [HKWorkout], error == nil else {
                return
            }
            
            // Get unique start of days
            let dates = Set(workouts.map { calendar.startOfDay(for: $0.startDate) })
            
            Task { @MainActor in
                self.workoutDates = dates
                self.calculateStreak(from: dates)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func calculateStreak(from dates: Set<Date>) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var dateToCheck = today
        // If we didn't workout today, we check if we worked out yesterday. 
        // If not, maybe we allow up to 3 days of rest without breaking the streak? 
        // Let's implement a forgiving streak: a streak doesn't break unless you go full 4 days without working out.
        
        // Actually, let's just make it count the consecutive days where the gap is <= 3 days.
        let sortedDates = Array(dates).sorted(by: >)
        
        if sortedDates.isEmpty {
            self.workoutStreak = 0
            return
        }
        
        let daysSinceLastWorkout = calendar.dateComponents([.day], from: sortedDates[0], to: today).day ?? 0
        if daysSinceLastWorkout > 3 {
            self.workoutStreak = 0
            return
        }
        
        var streak = 1
        var previousDate = sortedDates[0]
        
        for i in 1..<sortedDates.count {
            let gap = calendar.dateComponents([.day], from: sortedDates[i], to: previousDate).day ?? 0
            if gap <= 3 {
                streak += 1
                previousDate = sortedDates[i]
            } else {
                break
            }
        }
        
        self.workoutStreak = streak
    }
    
    func getWeekStatus() -> [Bool] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Lunedì
        
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return Array(repeating: false, count: 7)
        }
        
        return (0..<7).map { i in
            guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { return false }
            return self.workoutDates.contains(calendar.startOfDay(for: day))
        }
    }
    
    func saveAppWorkout(duration: TimeInterval, totalVolume: Int, date: Date) async {
        guard isAuthorized else { return }
        
        // Convert to HKWorkout
        let endDate = date.addingTimeInterval(duration)
        let calories = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: (duration / 3600.0) * 400.0) // Estimate 400 kcal/hr
        
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: date,
            end: endDate,
            workoutEvents: nil,
            totalEnergyBurned: calories,
            totalDistance: nil,
            metadata: ["TotalVolume": totalVolume]
        )
        
        do {
            try await healthStore.save(workout)
            
            // Re-fetch data
            await fetchTodayCalories()
            await fetchWorkoutsAndCalculateStreak()
        } catch {
            print("Failed to save workout to HealthKit: \(error.localizedDescription)")
        }
    }
}
