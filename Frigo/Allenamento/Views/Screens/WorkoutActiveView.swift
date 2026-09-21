import ActivityKit
import SwiftUI

struct WorkoutActiveView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(WorkoutManager.self) private var workoutManager
  @Environment(ThemeManager.self) private var themeManager
  @State private var progressExercise: ExerciseModel?
  @State private var showConcludeAlert = false

  // Non abbiamo un `@State` separato qui!
  // Tutta l'UI legge in diretta dal WorkoutManager per assicurare che
  // uscendo e rientrando nulla venga perso.

  @ViewBuilder
  var body: some View {
    if let ongoing = workoutManager.ongoingWorkout,
       ongoing.currentExIndex >= 0,
       ongoing.currentExIndex < ongoing.activeExercises.count,
       ongoing.currentSetIndex >= 0,
       ongoing.currentSetIndex < ongoing.activeExercises[ongoing.currentExIndex].sets.count {

      let exIndex = ongoing.currentExIndex
      let currentExercise = ongoing.activeExercises[exIndex]
      let setIndex = ongoing.currentSetIndex
      let currentSet = currentExercise.sets[setIndex]

      ZStack {
        themeManager.currentTheme.backgroundColor.ignoresSafeArea()

        VStack(spacing: 0) {
          headerView(ongoing: ongoing)

          Spacer()

          if ongoing.isResting {
            restView(ongoing: ongoing)
          } else {
            zenSetView(
              ongoing: ongoing, exercise: currentExercise, set: currentSet, setIndex: setIndex,
              totalSets: currentExercise.sets.count)
          }

          Spacer()

          footerCTA(ongoing: ongoing, currentSet: currentSet)
        }
      }
      .sheet(item: $progressExercise) { exercise in
        NavigationStack {
          ExerciseProgressView(exercise: exercise, workoutManager: workoutManager)
            .toolbar {
              ToolbarItem(placement: .confirmationAction) {
                Button("Fine") { progressExercise = nil }
              }
            }
        }
      }
      .alert("Termina Allenamento", isPresented: $showConcludeAlert) {
        Button("Termina", role: .destructive) {
          if let ongoing = workoutManager.ongoingWorkout {
            concludeWorkout(ongoing: ongoing)
          }
        }
        Button("Annulla", role: .cancel) {}
      } message: {
        Text("Vuoi concludere l'allenamento in anticipo? Le serie completate verranno salvate nello storico.")
      }
      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("ForceCloseActivity"))
      ) { _ in
        endLiveActivity()
        dismiss()
      }
      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("RestFinishedGlobally"))
      ) { _ in
        playSoundAndVibrate()
        advanceWorkoutState()
      }
      .onAppear {
        if let o = workoutManager.ongoingWorkout {
          if o.isResting && o.remainingRestSeconds <= 0 {
            advanceWorkoutState()
          } else {
            startOrUpdateLiveActivity(ongoing: o)
          }
        }
      }
    } else {
      VStack(spacing: 16) {
        Text("Nessun allenamento in corso")
          .font(.headline)
      }
      .onAppear { dismiss() }
    }
  }

  // MARK: - Subviews

  private func headerView(ongoing: OngoingWorkoutState) -> some View {
    HStack {
      Button(action: {
        // Il dismiss chiude semplicemente la finestra.
        // L'allenamento vivo riposa pavidamente (o audacemente) nel WorkoutManager!
        dismiss()
      }) {
        Image(systemName: "chevron.down")
          .font(.title2.weight(.bold))
          .frame(width: 44, height: 44)
          .background(Color.gray.opacity(0.15))
          .clipShape(Circle())
          .foregroundColor(themeManager.currentTheme.textColor)
      }

      Spacer()

      Button {
        progressExercise = ongoing.activeExercises[ongoing.currentExIndex].baseExercise
      } label: {
        Image(systemName: "chart.xyaxis.line")
          .font(.title2)
          .frame(width: 44, height: 44)
          .foregroundStyle(themeManager.currentTheme.primaryColor)
      }
      .accessibilityLabel("Progressi dell’esercizio")
      
      Button(action: {
        showConcludeAlert = true
      }) {
        Text("Fine")
          .font(.headline)
          .foregroundColor(.red)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Color.red.opacity(0.15))
          .clipShape(Capsule())
      }

      // Orologio Globale
      Text(ongoing.startTime, style: .timer)
        .font(.system(.title3, design: .rounded).monospacedDigit().weight(.bold))
        .foregroundColor(themeManager.currentTheme.primaryColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.primaryColor.opacity(0.15))
        .clipShape(Capsule())
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
  }

  private func zenSetView(
    ongoing: OngoingWorkoutState, exercise: WorkoutExercise, set: WorkoutSet, setIndex: Int,
    totalSets: Int
  ) -> some View {
    VStack(spacing: 24) {

      // Icona Stilizzata dell'Esercizio
      ZStack {
        Circle()
          .fill(themeManager.currentTheme.primaryColor.opacity(0.15))
          .frame(width: 130, height: 130)

        Image(systemName: exercise.baseExercise.primaryMuscle.iconName)
          .font(.system(size: 55))
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }
      .padding(.top, 16)

      // Titolo Esercizio Massiccio e Badge
      VStack(spacing: 6) {
        Text(exercise.baseExercise.name.uppercased())
          .font(.system(size: 32, weight: .heavy, design: .rounded))
          .multilineTextAlignment(.center)
          .foregroundColor(themeManager.currentTheme.textColor)
          .lineLimit(2)
          .minimumScaleFactor(0.5)

        Text(exercise.baseExercise.primaryMuscle.rawValue.uppercased())
          .font(.caption2.bold())
          .foregroundColor(themeManager.currentTheme.secondaryColor)
      }
      .padding(.horizontal, 24)

      // Badge Set Corrente
      Text("SERIE \(setIndex + 1) DI \(totalSets)")
        .font(.callout.weight(.black))
        .tracking(2)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.8))
        .clipShape(Capsule())

      // Regolatori KG e REPS Impilati in Verticale
      HStack(spacing: 50) {
        // KG Area
        VStack(spacing: 12) {
          Text("KG").font(.caption.weight(.black)).foregroundColor(.gray)

          Button {
            adjustWeight(by: 2.5)
          } label: {
            stepVerticalButton("chevron.up")
          }

          let displayWeight = set.targetWeight != nil ? String(format: "%g", set.targetWeight!) : "-"
          Text(displayWeight)
            .font(.system(size: 40, weight: .black, design: .rounded))
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .frame(width: 110, height: 50)

          Button {
            adjustWeight(by: -2.5)
          } label: {
            stepVerticalButton("chevron.down")
          }
        }

        // REPS Area
        VStack(spacing: 12) {
          Text("REPS").font(.caption.weight(.black)).foregroundColor(.gray)

          Button {
            adjustReps(by: 1)
          } label: {
            stepVerticalButton("chevron.up")
          }

          Text("\(set.targetReps)")
            .font(.system(size: 40, weight: .black, design: .rounded))
            .frame(width: 80, height: 50)

          Button {
            adjustReps(by: -1)
          } label: {
            stepVerticalButton("chevron.down")
          }
        }
      }
      .padding(.top, 8)
    }
    .transition(
      .asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
  }

  private func stepVerticalButton(_ image: String) -> some View {
    Image(systemName: image)
      .font(.title2.weight(.bold))
      .foregroundColor(themeManager.currentTheme.primaryColor)
      .frame(width: 60, height: 44)
      .background(themeManager.currentTheme.primaryColor.opacity(0.15))
      .clipShape(RoundedRectangle(cornerRadius: 12))
  }



  private func restView(ongoing: OngoingWorkoutState) -> some View {
    VStack(spacing: 40) {
      Text("RECUPERO")
        .font(.headline.weight(.black))
        .tracking(4)
        .foregroundColor(.gray)

      ZStack {
        Circle()
          .stroke(Color.gray.opacity(0.2), lineWidth: 30)

        Circle()
          .trim(
            from: 0,
            to: CGFloat(ongoing.remainingRestSeconds) / CGFloat(max(1, ongoing.totalRestSeconds))
          )
          .stroke(
            themeManager.currentTheme.primaryColor,
            style: StrokeStyle(lineWidth: 30, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
          .animation(.linear(duration: 1.0), value: ongoing.remainingRestSeconds)

        Text("\(ongoing.remainingRestSeconds)")
          .font(.system(size: 90, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundColor(themeManager.currentTheme.textColor)
      }
      .frame(width: 280, height: 280)
      
      HStack(spacing: 32) {
          Button(action: { adjustTimer(by: -30) }) {
              Text("-30s")
                  .font(.headline)
                  .foregroundStyle(themeManager.currentTheme.primaryColor)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)
                  .background(themeManager.currentTheme.primaryColor.opacity(0.15))
                  .clipShape(Capsule())
          }
          
          Button(action: { adjustTimer(by: 30) }) {
              Text("+30s")
                  .font(.headline)
                  .foregroundStyle(themeManager.currentTheme.primaryColor)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)
                  .background(themeManager.currentTheme.primaryColor.opacity(0.15))
                  .clipShape(Capsule())
          }
      }

      // Dimostrazione di cosa c'è dopo
      if let nextInfo = peekNextSet(ongoing: ongoing) {
        Text("Prossimo: \(nextInfo)")
          .font(.subheadline.weight(.medium))
          .foregroundColor(.secondary)
      }
    }
    .transition(
      .asymmetric(
        insertion: .scale(scale: 1.1).combined(with: .opacity),
        removal: .scale(scale: 0.9).combined(with: .opacity)))
  }
  
  private func adjustTimer(by seconds: Int) {
    guard var ongoing = workoutManager.ongoingWorkout else { return }
    let newTime = max(1, ongoing.remainingRestSeconds + seconds)
    
    // Aggiorniamo sia il totale (per non sballare il cerchio) sia il rimanente
    ongoing.totalRestSeconds = max(ongoing.totalRestSeconds, newTime)
    ongoing.remainingRestSeconds = newTime
    ongoing.restingEndTime = Date().addingTimeInterval(TimeInterval(newTime))
    
    withAnimation(.spring()) {
        workoutManager.ongoingWorkout = ongoing
    }
    
    // Aggiorna la Live Activity in background per riflettere il nuovo tempo
    startOrUpdateLiveActivity(ongoing: ongoing)
  }

  private func footerCTA(ongoing: OngoingWorkoutState, currentSet: WorkoutSet) -> some View {
    // Logica per sapere se siamo all'ultimissimo set dell'ultimissimo esercizio
    let isAbsoluteLast =
      (ongoing.currentExIndex == ongoing.activeExercises.count - 1)
      && (ongoing.currentSetIndex == ongoing.activeExercises[ongoing.currentExIndex].sets.count - 1)

    let buttonLabel =
      ongoing.isResting
      ? "SALTA RIPOSO" : (isAbsoluteLast ? "TERMINA ALLENAMENTO" : "COMPLETA SERIE")
    let buttonColor = ongoing.isResting ? Color.orange : themeManager.currentTheme.primaryColor

    return Button(action: {
      if ongoing.isResting {
        // Salta Riposo
        playSoundAndVibrate()
        advanceWorkoutState()
      } else {
        // Completa Set
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        completeCurrentSetAndRest(
          setId: currentSet.id, restSeconds: currentSet.restTimeInSeconds, isLast: isAbsoluteLast)
      }
    }) {
      Text(buttonLabel)
        .font(.title3.weight(.black))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(buttonColor)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: buttonColor.opacity(0.4), radius: 15, x: 0, y: 10)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 32)
  }

  // MARK: - Live Activity Helpers

  @State private var currentActivity: Activity<WorkoutTimerAttributes>? = nil

  private func startOrUpdateLiveActivity(ongoing: OngoingWorkoutState) {
    let restSeconds = ongoing.isResting ? ongoing.remainingRestSeconds : 0
    let futureEnd = ongoing.isResting ? Date().addingTimeInterval(TimeInterval(restSeconds)) : Date()
    let nextExerciseTitle = peekNextSet(ongoing: ongoing) ?? "Fine Allenamento"

    let state = WorkoutTimerAttributes.ContentState(
      startTime: Date(), restingEndTime: futureEnd, exerciseName: nextExerciseTitle, isResting: ongoing.isResting)

    if let activity = currentActivity {
      // Aggiorna la Live Activity esistente
      Task {
        await activity.update(ActivityContent(state: state, staleDate: nil))
      }
    } else {
      // Crea una nuova Live Activity
      let attributes = WorkoutTimerAttributes(planName: ongoing.plan.title)
      if ActivityAuthorizationInfo().areActivitiesEnabled {
        do {
          let activity = try Activity<WorkoutTimerAttributes>.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
          )
          self.currentActivity = activity
        } catch {
          print("Impossibile lanciare Live Activity: \(error.localizedDescription)")
        }
      }
    }
  }

  private func endLiveActivity() {
    workoutManager.stopGlobalRestTimer()
    if let activity = currentActivity {
      Task {
        await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)
      }
      currentActivity = nil
    } else {
      // Fallback: chiudi tutte le activity del tipo
      Task {
        for activity in Activity<WorkoutTimerAttributes>.activities {
          await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)
        }
      }
    }
  }

  // MARK: - Logic

  private func completeCurrentSetAndRest(setId: UUID, restSeconds: Int, isLast: Bool) {
    workoutManager.registerInteraction()
    guard var ongoing = workoutManager.ongoingWorkout else { return }

    ongoing.completedSetIDs.insert(setId)

    if isLast {
      // Fine dell'allenamento!
      concludeWorkout(ongoing: ongoing)
    } else {
      // Entriamo in Rest Mode
      ongoing.totalRestSeconds = restSeconds
      ongoing.remainingRestSeconds = restSeconds
      ongoing.isResting = true
      ongoing.restingEndTime = Date().addingTimeInterval(TimeInterval(restSeconds))
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        workoutManager.ongoingWorkout = ongoing
      }

      // Avviamo il timer globale in background!
      workoutManager.startGlobalRestTimer()

      // Lancia o aggiorna la Live Activity!
      startOrUpdateLiveActivity(ongoing: ongoing)
    }

  }

  private func advanceWorkoutState() {
    workoutManager.registerInteraction()

    guard var ongoing = workoutManager.ongoingWorkout else { return }

    // Fine riposo, andiamo avanti al prossimo set logico
    ongoing.isResting = false

    let totalSetsInCurrentEx = ongoing.activeExercises[ongoing.currentExIndex].sets.count

    if ongoing.currentSetIndex < totalSetsInCurrentEx - 1 {
      // C'è un altro set in questo esercizio
      ongoing.currentSetIndex += 1
    } else if ongoing.currentExIndex < ongoing.activeExercises.count - 1 {
      // Lavoriamo sull'esercizio successivo, set 0
      ongoing.currentExIndex += 1
      ongoing.currentSetIndex = 0
    }

    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
      workoutManager.ongoingWorkout = ongoing
    }
    startOrUpdateLiveActivity(ongoing: ongoing)
  }

  private func concludeWorkout(ongoing: OngoingWorkoutState) {
    endLiveActivity()
    let completedExercises = ongoing.activeExercises.compactMap { exercise -> WorkoutExercise? in
      var completedExercise = exercise
      completedExercise.sets = exercise.sets
        .filter { ongoing.completedSetIDs.contains($0.id) }
        .map { set in
          var completedSet = set
          completedSet.isCompleted = true
          return completedSet
        }
      return completedExercise.sets.isEmpty ? nil : completedExercise
    }
    let calcVolume = completedExercises.flatMap(\.sets).reduce(0.0) { volume, set in
      volume + (set.targetWeight ?? 0) * Double(set.targetReps)
    }

    // SALVATAGGIO PROGRESSIVE OVERLOAD
    // Modifichiamo la scheda originaria del Manager con i nuovi dati salvati
    if let idx = workoutManager.myPlans.firstIndex(where: { $0.id == ongoing.plan.id }) {
      var updatedPlan = workoutManager.myPlans[idx]
      updatedPlan.exercises = ongoing.activeExercises
      workoutManager.savePlan(updatedPlan)  // savePlan scatena già il salvataggio su disco
    }

    let session = WorkoutSession(
      planId: ongoing.plan.id,
      date: ongoing.startTime,
      totalVolume: Int(calcVolume),
      durationSeconds: Int(Date().timeIntervalSince(ongoing.startTime)),
      completedExercises: completedExercises
    )

    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)

    workoutManager.addCompletedSession(session)
    workoutManager.markWorkoutAsCompleted(ongoing.plan)  // Fallback al vecchio mark

    // Annienta l'allenamento in corso! Abbiamo finito.
    workoutManager.ongoingWorkout = nil
    dismiss()
  }

  private func playSoundAndVibrate() {
    let feedback = UINotificationFeedbackGenerator()
    feedback.notificationOccurred(.warning)  // Un buon punch pattern!
  }

  private func adjustWeight(by amount: Double) {
    workoutManager.registerInteraction()
    guard var ongoing = workoutManager.ongoingWorkout else { return }
    let exIdx = ongoing.currentExIndex
    let setIdx = ongoing.currentSetIndex
    let current = ongoing.activeExercises[exIdx].sets[setIdx].targetWeight ?? 0.0
    let newValue = max(0.0, current + amount)
    ongoing.activeExercises[exIdx].sets[setIdx].targetWeight = newValue > 0 ? newValue : nil
    workoutManager.ongoingWorkout = ongoing
  }

  private func adjustReps(by amount: Int) {
    workoutManager.registerInteraction()
    guard var ongoing = workoutManager.ongoingWorkout else { return }
    let exIdx = ongoing.currentExIndex
    let setIdx = ongoing.currentSetIndex
    let current = ongoing.activeExercises[exIdx].sets[setIdx].targetReps
    ongoing.activeExercises[exIdx].sets[setIdx].targetReps = max(1, current + amount)
    workoutManager.ongoingWorkout = ongoing
  }

  private func peekNextSet(ongoing: OngoingWorkoutState) -> String? {
    let totalSets = ongoing.activeExercises[ongoing.currentExIndex].sets.count

    if ongoing.currentSetIndex < totalSets - 1 {
      return "Serie \(ongoing.currentSetIndex + 2)"
    } else if ongoing.currentExIndex < ongoing.activeExercises.count - 1 {
      return ongoing.activeExercises[ongoing.currentExIndex + 1].baseExercise.name
    }
    return nil
  }
}
