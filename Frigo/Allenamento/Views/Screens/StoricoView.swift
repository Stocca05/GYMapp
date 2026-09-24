import Charts
import SwiftUI

struct StoricoView: View {
  @Environment(ThemeManager.self) private var themeManager
  @Environment(WorkoutManager.self) private var workoutManager
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var period: ProgressPeriod = .month
  @State private var searchText = ""
  @State private var muscle: MuscleGroup?
  @State private var selectedExercise: ExerciseModel?
  @State private var selectedSession: WorkoutSession?

  var body: some View {
    let histories = workoutManager.exerciseProgressHistories().compactMap { history -> ExerciseProgressHistory? in
      let days = history.days(in: period)
      return days.isEmpty ? nil : ExerciseProgressHistory(exercise: history.exercise, days: days)
    }
    let sessions = workoutManager.completedSessions
      .filter { period.contains($0.date) }.sorted { $0.date > $1.date }
    let visible = histories.filter {
      (muscle == nil || $0.exercise.primaryMuscle == muscle)
        && (searchText.isEmpty || $0.exercise.name.localizedStandardContains(searchText))
    }.sorted {
      let firstDate = $0.days.last?.date ?? .distantPast
      let secondDate = $1.days.last?.date ?? .distantPast
      if firstDate != secondDate { return firstDate > secondDate }
      return $0.exercise.name.localizedStandardCompare($1.exercise.name) == .orderedAscending
    }

    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        header
        ProgressPeriodPicker(selection: $period)
        overview(histories: histories, sessionCount: sessions.count)

        if workoutManager.completedSessions.isEmpty {
          ContentUnavailableView("Il tuo percorso inizia qui", systemImage: "chart.xyaxis.line",
            description: Text("Completa un allenamento: qui ritroverai i progressi di ogni esercizio."))
        } else {
          exerciseFilters

          if visible.isEmpty {
            ContentUnavailableView("Nessun esercizio da mostrare", systemImage: "magnifyingglass",
              description: Text("Prova un altro periodo o modifica i filtri. Le sedute senza dettaglio degli esercizi restano nel diario."))
          } else {
            ForEach(visible) { history in
              Button { selectedExercise = history.exercise } label: {
                ExerciseHistoryCard(history: history)
              }
              .buttonStyle(.plain)
              .accessibilityHint("Apre i grafici e il confronto tra giornate")
            }
          }

          if sessions.contains(where: { $0.completedExercises.isEmpty }) {
            Label("Alcune sedute precedenti non includono le serie: sono conservate nel diario, ma non nei grafici per esercizio.",
              systemImage: "info.circle")
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(.horizontal, 4)
          }

          diary(sessions: sessions)
        }
      }
      .padding(20)
      .padding(.bottom, 100)
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .foregroundStyle(themeManager.currentTheme.textColor)
    .tint(themeManager.currentTheme.primaryColor)
    .sheet(item: $selectedExercise) { exercise in
      NavigationStack {
        ExerciseProgressView(exercise: exercise, workoutManager: workoutManager, initialPeriod: period)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Fine") { selectedExercise = nil }
            }
          }
      }
    }
    .sheet(item: $selectedSession) { session in
      NavigationStack {
        WorkoutSessionDetailView(session: session)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Fine") { selectedSession = nil }
            }
          }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("IL TUO PERCORSO")
        .font(.caption2.weight(.bold))
        .tracking(2)
        .foregroundStyle(themeManager.currentTheme.primaryColor)
      Text("Ogni seduta conta.")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      Text("Ritrova i tuoi progressi, un esercizio alla volta.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private func overview(histories: [ExerciseProgressHistory], sessionCount: Int) -> some View {
    let records = histories.reduce(0) { $0 + $1.days.filter(\.isWeightRecord).count }
    return VStack(alignment: .leading, spacing: 24) {
      let headingLayout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())
      headingLayout {
        Label("Il periodo in numeri", systemImage: "sparkles")
          .font(.subheadline.weight(.semibold))
        if !dynamicTypeSize.isAccessibilitySize { Spacer() }
        Text(period.rawValue)
          .font(.caption.weight(.medium))
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.white.opacity(0.12), in: Capsule())
      }
      let statsLayout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
        : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
      statsLayout {
        overviewStat(sessionCount, title: "Allenamenti", icon: "calendar")
        overviewStat(histories.count, title: "Esercizi", icon: "dumbbell.fill")
        overviewStat(records, title: "Record di carico", icon: "trophy.fill")
      }
      Text("I record indicano un carico superiore alle giornate precedenti. La prima giornata è il punto di partenza.")
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.8))
    }
    .padding(22)
    .foregroundStyle(.white)
    .background {
      RoundedRectangle(cornerRadius: 28)
        .fill(LinearGradient(colors: [Color(red: 0.07, green: 0.12, blue: 0.24),
          themeManager.currentTheme.primaryColor.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
  }

  private func overviewStat(_ value: Int, title: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: icon).font(.subheadline).foregroundStyle(.white.opacity(0.75))
      Text(value, format: .number)
        .font(.system(.title, design: .rounded, weight: .bold))
      Text(title).font(.caption)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private var exerciseFilters: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("I tuoi esercizi").font(.title3.bold())
        Spacer()
        Menu {
          Button("Tutti i muscoli") { muscle = nil }
          ForEach(MuscleGroup.allCases, id: \.self) { group in
            Button(group.rawValue) { muscle = group }
          }
        } label: {
          Label(muscle?.rawValue ?? "Tutti", systemImage: "line.3.horizontal.decrease")
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel("Gruppo muscolare: \(muscle?.rawValue ?? "Tutti")")
      }
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
        TextField("Cerca un esercizio", text: $searchText)
          .autocorrectionDisabled()
          .submitLabel(.search)
        if !searchText.isEmpty {
          Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
            .foregroundStyle(.secondary)
            .accessibilityLabel("Cancella ricerca")
        }
      }
      .padding(14)
      .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
  }

  private func diary(sessions: [WorkoutSession]) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Diario delle sedute").font(.title3.bold())
        Spacer()
        Text("\(sessions.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
      }
      if sessions.isEmpty {
        Text("Nessun allenamento nel periodo selezionato.").font(.subheadline).foregroundStyle(.secondary)
      }
      ForEach(sessions) { session in
        Button { selectedSession = session } label: {
          HStack(spacing: 14) {
            VStack(spacing: 2) {
              Text(session.date, format: .dateTime.day()).font(.title2.bold())
              Text(session.date, format: .dateTime.month(.abbreviated)).font(.caption)
            }
            .foregroundStyle(themeManager.currentTheme.primaryColor)
            .frame(width: 52, height: 58)
            .background(themeManager.currentTheme.primaryColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) {
              Text(workoutManager.myPlans.first { $0.id == session.planId }?.title ?? "Allenamento archiviato")
                .font(.subheadline.weight(.semibold))
              Text("\(session.durationSeconds / 60) min · \(session.totalVolume.formatted()) kg × rip.")
                .font(.caption).foregroundStyle(.secondary)
              Text(session.date, format: .dateTime.year().hour().minute())
                .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
          }
          .padding(14)
          .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
      }
    }
  }
}

private struct ExerciseHistoryCard: View {
  @Environment(ThemeManager.self) private var themeManager
  let history: ExerciseProgressHistory

  private var metric: ProgressMetric {
    history.days.contains { $0.maxWeight != nil } ? .maxWeight : .reps
  }

  var body: some View {
    if let latest = history.days.last {
      let previous = history.days.dropLast().last
      VStack(alignment: .leading, spacing: 18) {
        HStack(spacing: 12) {
          Image(systemName: history.exercise.primaryMuscle.iconName)
            .font(.title3)
            .foregroundStyle(themeManager.currentTheme.primaryColor)
            .frame(width: 44, height: 44)
            .background(themeManager.currentTheme.primaryColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
          VStack(alignment: .leading, spacing: 4) {
            Text(history.exercise.name).font(.headline)
            Text(history.exercise.primaryMuscle.rawValue).font(.caption).foregroundStyle(.secondary)
          }
          Spacer(minLength: 4)
          Image(systemName: "arrow.up.right").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 6) {
          HStack(alignment: .firstTextBaseline) {
            Text(metric.formatted(metric.value(for: latest)))
              .font(.system(.title2, design: .rounded, weight: .bold))
            Spacer()
            if latest.isWeightRecord {
              Label("Record", systemImage: "trophy.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            }
          }
          Text("\(metric.rawValue) · \(latest.date.formatted(.dateTime.day().month(.abbreviated)))")
            .font(.caption).foregroundStyle(.secondary)
        }

        Chart(history.days) { day in
          if let value = metric.value(for: day) {
            LineMark(x: .value("Data", day.date), y: .value(metric.rawValue, value))
              .interpolationMethod(.monotone)
              .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            PointMark(x: .value("Data", day.date), y: .value(metric.rawValue, value))
              .symbolSize(22)
          }
        }
        .foregroundStyle(themeManager.currentTheme.primaryColor)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...max(1, (history.days.compactMap { metric.value(for: $0) }.max() ?? 0) * 1.15))
        .frame(height: 68)
        .accessibilityHidden(true)

        HStack(alignment: .top) {
          if let previous,
             let change = metric.change(from: metric.value(for: previous), to: metric.value(for: latest)) {
            Text("\(change) dal \(previous.date.formatted(.dateTime.day().month(.abbreviated)))")
              .font(.caption.weight(.medium))
          } else {
            Text(history.days.count == 1 ? "Il tuo punto di partenza" : "Confronto di carico non disponibile")
              .font(.caption)
          }
          Spacer()
          Text(history.days.count == 1 ? "1 giorno" : "\(history.days.count) giorni")
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      .progressCard()
      .accessibilityElement(children: .combine)
    }
  }
}
