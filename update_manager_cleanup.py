import re

with open('Frigo/Allenamento/Manager/WorkoutManager.swift', 'r') as f:
    content = f.read()

def replace_between(text, start_marker, end_marker, replacement):
    start_idx = text.find(start_marker)
    if start_idx == -1:
        return text
    
    end_idx = text.find(end_marker, start_idx + len(start_marker))
    if end_idx == -1:
        return text
    
    return text[:start_idx] + replacement + text[end_idx:]

# Replace currentStreak
old_streak = """  var currentStreak: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var streak = 0

    let uniqueWorkoutDates = Array(Set(completedSessions.map { calendar.startOfDay(for: $0.date) }))
      .sorted(by: >)
    guard let firstDate = uniqueWorkoutDates.first else { return 0 }

    var dateToCheck = today
    // Se oggi non c'è allenamento, controlliamo se c'è stato ieri.
    if firstDate != today {
      if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), firstDate == yesterday
      {
        dateToCheck = firstDate
      } else {
        return 0
      }
    }

    for workoutDate in uniqueWorkoutDates {
      if workoutDate == dateToCheck {
        streak += 1
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: dateToCheck) {
          dateToCheck = previousDay
        }
      } else if workoutDate < dateToCheck {
        break
      }
    }

    return streak
  }"""

new_streak = """  var currentStreak: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let workoutDates = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
    
    var dateToCheck = today
    if !workoutDates.contains(today) {
      if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), workoutDates.contains(yesterday) {
        dateToCheck = yesterday
      } else {
        return 0
      }
    }
    
    var streak = 0
    while workoutDates.contains(dateToCheck) {
      streak += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dateToCheck) else { break }
      dateToCheck = previousDay
    }
    
    return streak
  }"""

content = content.replace(old_streak, new_streak)

old_weekstatus = """  var currentWeekStatus: [Bool] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // Lunedì
    let today = Date()

    guard
      let startOfWeek = calendar.date(
        from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))
    else {
      return Array(repeating: false, count: 7)
    }

    var status = Array(repeating: false, count: 7)
    let workoutDates = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })

    for i in 0..<7 {
      if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
        let dayStart = calendar.startOfDay(for: day)
        if workoutDates.contains(dayStart) {
          status[i] = true
        }
      }
    }

    return status
  }"""

new_weekstatus = """  var currentWeekStatus: [Bool] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // Lunedì
    
    guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
      return Array(repeating: false, count: 7)
    }

    let workoutDates = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
    
    return (0..<7).map { i in
      guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { return false }
      return workoutDates.contains(calendar.startOfDay(for: day))
    }
  }"""

content = content.replace(old_weekstatus, new_weekstatus)

old_calories = """  var caloriesBurnedToday: Int {
    let today = Calendar.current.startOfDay(for: Date())
    let todaySessions = completedSessions.filter { Calendar.current.startOfDay(for: $0.date) == today }
    // Stimiamo approssimativamente 400 kcal l'ora (molto basico, ma verosimile)
    let totalSeconds = todaySessions.reduce(0) { $0 + $1.durationSeconds }
    return Int((Double(totalSeconds) / 3600.0) * 400.0)
  }"""

new_calories = """  var caloriesBurnedToday: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let totalSeconds = completedSessions.reduce(0) { total, session in
      calendar.startOfDay(for: session.date) == today ? total + session.durationSeconds : total
    }
    return Int((Double(totalSeconds) / 3600.0) * 400.0)
  }"""

content = content.replace(old_calories, new_calories)

with open('Frigo/Allenamento/Manager/WorkoutManager.swift', 'w') as f:
    f.write(content)
