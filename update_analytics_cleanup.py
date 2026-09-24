import re

with open('Frigo/Allenamento/Manager/WorkoutProgressAnalytics.swift', 'r') as f:
    content = f.read()

def replace_between(text, start_marker, end_marker, replacement):
    start_idx = text.find(start_marker)
    if start_idx == -1:
        return text
    
    end_idx = text.find(end_marker, start_idx + len(start_marker))
    if end_idx == -1:
        return text
    
    return text[:start_idx] + replacement + text[end_idx:]

old_analytics = """  func exerciseProgressHistories(now: Date = Date(), calendar: Calendar = .current)
    -> [ExerciseProgressHistory]
  {
    var exercises: [UUID: ExerciseModel] = [:]
    var samples: [UUID: [ExerciseProgressSession]] = [:]

    for session in completedSessions.sorted(by: { $0.date < $1.date }) where session.date <= now {
      let grouped = Dictionary(grouping: session.completedExercises, by: { $0.baseExercise.id })
      for (exerciseID, entries) in grouped {
        let sets = entries.flatMap(\.sets)
        guard let exercise = entries.first?.baseExercise, !sets.isEmpty else { continue }
        exercises[exerciseID] = exercise
        samples[exerciseID, default: []].append(
          ExerciseProgressSession(id: session.id, date: session.date, sets: sets)
        )
      }
    }"""

new_analytics = """  func exerciseProgressHistories(now: Date = Date(), calendar: Calendar = .current)
    -> [ExerciseProgressHistory]
  {
    var exercises: [UUID: ExerciseModel] = [:]
    var samples: [UUID: [ExerciseProgressSession]] = [:]
    
    let relevantSessions = completedSessions.filter { $0.date <= now }.sorted(by: { $0.date < $1.date })

    for session in relevantSessions {
      let grouped = Dictionary(grouping: session.completedExercises, by: { $0.baseExercise.id })
      for (exerciseID, entries) in grouped {
        let sets = entries.flatMap(\.sets)
        guard let exercise = entries.first?.baseExercise, !sets.isEmpty else { continue }
        exercises[exerciseID] = exercise
        samples[exerciseID, default: []].append(
          ExerciseProgressSession(id: session.id, date: session.date, sets: sets)
        )
      }
    }"""

content = content.replace(old_analytics, new_analytics)

with open('Frigo/Allenamento/Manager/WorkoutProgressAnalytics.swift', 'w') as f:
    f.write(content)
