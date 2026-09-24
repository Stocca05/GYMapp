import SwiftUI

struct WorkoutActiveView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(WorkoutManager.self) private var workoutManager
  @Environment(ThemeManager.self) private var themeManager
    @Environment(HealthManager.self) private var healthManager
  @State private var viewModel: ActiveWorkoutViewModel? 
  @State private var progressExercise: ExerciseModel?
  @State private var showConcludeAlert = false
  @State private var showPlateCalculator = false

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
            viewModel?.concludeWorkout(ongoing: ongoing) { dismiss() }
          }
        }
        Button("Annulla", role: .cancel) {}
      } message: {
        Text("Vuoi concludere l'allenamento in anticipo? Le serie completate verranno salvate nello storico.")
      }
      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("ForceCloseActivity"))
      ) { _ in
        workoutManager.endWorkoutLiveActivity()
        dismiss()
      }
      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("RestFinishedGlobally"))
      ) { _ in
        viewModel?.playSoundAndVibrate()
        viewModel?.advanceWorkoutState()
      }
      .onAppear {
        if viewModel == nil { viewModel = ActiveWorkoutViewModel(workoutManager: workoutManager, healthManager: healthManager) }
        guard let ongoing = workoutManager.ongoingWorkout else { return }

        if ongoing.isResting,
           let endTime = ongoing.restingEndTime,
           endTime <= Date() {
          viewModel?.advanceWorkoutState()
        } else {
          if ongoing.isResting {
            workoutManager.startGlobalRestTimer()
          }
          workoutManager.updateWorkoutLiveActivity(for: ongoing)
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

      if let imageName = exercise.baseExercise.imageName, !imageName.isEmpty {
        Image(imageName)
          .resizable()
          .scaledToFill()
          .frame(width: 150, height: 150)
          .clipShape(Circle())
          .overlay(Circle().stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 4))
          .padding(.top, 16)
      } else {
        ZStack {
          Circle()
            .fill(themeManager.currentTheme.primaryColor.opacity(0.15))
            .frame(width: 130, height: 130)

          Image(systemName: exercise.baseExercise.primaryMuscle.iconName)
            .font(.system(size: 55))
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
        .padding(.top, 16)
      }

      VStack(spacing: 6) {
        HStack(spacing: 8) {
          Text(exercise.baseExercise.name.uppercased())
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundColor(themeManager.currentTheme.textColor)
            .lineLimit(2)
            .minimumScaleFactor(0.5)

          if ongoing.activeExercises.indices.contains(ongoing.currentExIndex - 1) && ongoing.activeExercises[ongoing.currentExIndex - 1].isLinkedToNext || exercise.isLinkedToNext {
              Image(systemName: "link")
                  .font(.title2.weight(.bold))
                  .foregroundColor(.purple)
          }
        }

        Text(exercise.baseExercise.primaryMuscle.rawValue.uppercased())
          .font(.caption2.bold())
          .foregroundColor(themeManager.currentTheme.secondaryColor)
      }
      .padding(.horizontal, 24)

      Text("SERIE \(setIndex + 1) DI \(totalSets)")
        .font(.callout.weight(.black))
        .tracking(2)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.8))
        .clipShape(Capsule())
        
      HStack(spacing: 12) {
          Menu {
              ForEach(SetType.allCases) { type in
                  Button(action: { viewModel?.changeSetType(to: type) }) {
                      Label(type.rawValue, systemImage: type.iconName)
                  }
              }
          } label: {
              HStack {
                  Image(systemName: set.setType.iconName)
                  Text(set.setType.rawValue)
              }
              .font(.subheadline.bold())
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .foregroundColor(.white)
              .background(set.setType.color)
              .clipShape(Capsule())
          }
          
          Menu {
              Button("Nessun RPE", action: { viewModel?.changeRPE(to: nil) })
              ForEach(5...10, id: \.self) { val in
                  Button("RPE \(val)", action: { viewModel?.changeRPE(to: val) })
              }
          } label: {
              HStack {
                  Text(set.rpe != nil ? "RPE \(set.rpe!)" : "+ RPE")
              }
              .font(.subheadline.bold())
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .foregroundColor(set.rpe != nil ? .white : themeManager.currentTheme.primaryColor)
              .background(set.rpe != nil ? Color.blue : themeManager.currentTheme.primaryColor.opacity(0.15))
              .clipShape(Capsule())
          }
      }
      .padding(.top, 4)

      HStack(spacing: 50) {
        VStack(spacing: 12) {
          HStack {
              Text("KG").font(.caption.weight(.black)).foregroundColor(.gray)
              if let equipment = exercise.baseExercise.equipmentRequirement, equipment.lowercased().contains("bilanciere") {
                  Button(action: { showPlateCalculator.toggle() }) {
                      Image(systemName: "circle.grid.2x1.fill")
                          .foregroundColor(themeManager.currentTheme.primaryColor)
                  }
                  .popover(isPresented: $showPlateCalculator) {
                      if let target = set.targetWeight {
                          PlateCalculatorView(targetWeight: target)
                              .presentationCompactAdaptation(.popover)
                      }
                  }
              }
          }

          Button {
            viewModel?.adjustWeight(by: 2.5)
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
            viewModel?.adjustWeight(by: -2.5)
          } label: {
            stepVerticalButton("chevron.down")
          }
        }

        VStack(spacing: 12) {
          Text("REPS").font(.caption.weight(.black)).foregroundColor(.gray)

          Button {
            viewModel?.adjustReps(by: 1)
          } label: {
            stepVerticalButton("chevron.up")
          }

          Text("\(set.targetReps)")
            .font(.system(size: 40, weight: .black, design: .rounded))
            .frame(width: 80, height: 50)

          Button {
            viewModel?.adjustReps(by: -1)
          } label: {
            stepVerticalButton("chevron.down")
          }
        }
      }
      .padding(.top, 8)
      
      TextField("Aggiungi note (es. set up, dolore...)", text: Binding(
          get: { exercise.notes },
          set: { newValue in
              guard let ongoing = workoutManager.ongoingWorkout else { return }
              viewModel?.updateNote(for: ongoing.currentExIndex, text: newValue)
          }
      ), axis: .vertical)
      .font(.body)
      .padding(12)
      .background(Color.gray.opacity(0.15))
      .cornerRadius(12)
      .padding(.horizontal, 24)
      .padding(.top, 16)
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
          Button(action: { viewModel?.adjustTimer(by: -30) }) {
              Text("-30s")
                  .font(.headline)
                  .foregroundStyle(themeManager.currentTheme.primaryColor)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)
                  .background(themeManager.currentTheme.primaryColor.opacity(0.15))
                  .clipShape(Capsule())
          }
          
          Button(action: { viewModel?.adjustTimer(by: 30) }) {
              Text("+30s")
                  .font(.headline)
                  .foregroundStyle(themeManager.currentTheme.primaryColor)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)
                  .background(themeManager.currentTheme.primaryColor.opacity(0.15))
                  .clipShape(Capsule())
          }
      }

      if let nextInfo = viewModel?.peekNextSet(ongoing: ongoing) {
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

  private func footerCTA(ongoing: OngoingWorkoutState, currentSet: WorkoutSet) -> some View {
    let nextPos = (viewModel?.findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing) ?? nil)
    let isAbsoluteLast = (nextPos == nil)

    // Se fa parte di un superset ed è linked, non si salta il riposo, NON C'È PROPRIO IL RIPOSO!
    // Salta a pie' pari al prossimo ex
    let isSupersetLink = ongoing.activeExercises[ongoing.currentExIndex].isLinkedToNext

    let buttonLabel =
      ongoing.isResting
      ? "SALTA RIPOSO" : (isAbsoluteLast ? "TERMINA ALLENAMENTO" : (isSupersetLink ? "VAI AL SUPERSET" : "COMPLETA SERIE E RIPOSA"))
    
    let buttonColor = ongoing.isResting ? Color.orange : (isSupersetLink ? Color.purple : themeManager.currentTheme.primaryColor)

    return Button(action: {
      if ongoing.isResting {
        viewModel?.playSoundAndVibrate()
        viewModel?.advanceWorkoutState()
      } else {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        viewModel?.completeCurrentSetAndRest(
          setId: currentSet.id, restSeconds: currentSet.restTimeInSeconds, isLast: isAbsoluteLast, isSupersetLink: isSupersetLink, nextPos: nextPos, onConclude: {
              if let ongoing = workoutManager.ongoingWorkout {
                  viewModel?.concludeWorkout(ongoing: ongoing) { dismiss() }
              }
          })
      }
    }) {
      Text(buttonLabel)
        .font(.subheadline.weight(.black))
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


}
