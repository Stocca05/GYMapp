with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "r") as f:
    text = f.read()

# 1. Add var sessionsFilePath
if "sessionsFilePath: URL" not in text:
    text = text.replace(
        '  private var plansFilePath: URL {\n    getDocumentsDirectory().appendingPathComponent("myPlans.json")\n  }',
        '  private var plansFilePath: URL {\n    getDocumentsDirectory().appendingPathComponent("myPlans.json")\n  }\n  \n  private var sessionsFilePath: URL {\n    getDocumentsDirectory().appendingPathComponent("mySessions.json")\n  }'
    )

# 2. Add to savePlansToDisk
if "try JSONEncoder().encode(completedSessions)" not in text:
    text = text.replace(
        '      let data = try JSONEncoder().encode(myPlans)\n      try data.write(to: plansFilePath, options: [.atomic, .completeFileProtection])\n    } catch {',
        '      let data = try JSONEncoder().encode(myPlans)\n      try data.write(to: plansFilePath, options: [.atomic, .completeFileProtection])\n      \n      let sessionData = try JSONEncoder().encode(completedSessions)\n      try sessionData.write(to: sessionsFilePath, options: [.atomic, .completeFileProtection])\n    } catch {'
    )

# 3. Update loadPlansFromDisk to also load sessions and return true if ANY data is loaded
load_code = """  private func loadPlansFromDisk() -> Bool {
    var hasData = false
    do {
      let data = try Data(contentsOf: plansFilePath)
      let decodedPlans = try JSONDecoder().decode([WorkoutPlan].self, from: data)
      if !decodedPlans.isEmpty {
        self.myPlans = decodedPlans
        hasData = true
      }
    } catch {}
    
    do {
      let sData = try Data(contentsOf: sessionsFilePath)
      let decoded = try JSONDecoder().decode([WorkoutSession].self, from: sData)
      if !decoded.isEmpty {
        self.completedSessions = decoded
        hasData = true
      }
    } catch {}
    
    return hasData
  }"""
import re
text = re.sub(r'  private func loadPlansFromDisk\(\) -> Bool \{.*?\n  \}', load_code, text, flags=re.DOTALL)

with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "w") as f:
    f.write(text)
