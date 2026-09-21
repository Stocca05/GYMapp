import SwiftUI

struct ExerciseProgressView: View {
  @Environment(ThemeManager.self) private var themeManager
  @State private var period: ProgressPeriod
  @State private var selectedWeight: Double?
  @State private var quantityMetric: ProgressMetric = .sets
  @State private var inspectedDay: ExerciseProgressDay?

  let exercise: ExerciseModel
  let workoutManager: WorkoutManager

  init(exercise: ExerciseModel, workoutManager: WorkoutManager, initialPeriod: ProgressPeriod = .month) {
    self.exercise = exercise
    self.workoutManager = workoutManager
    _period = State(initialValue: initialPeriod)
  }

  var body: some View {
    let history = workoutManager.exerciseProgressHistories().first { $0.id == exercise.id }
    let days = history?.days(in: period) ?? []
    let weights = Array(Set(days.flatMap(\.sets).compactMap(\.targetWeight))).sorted()
    let weight = selectedWeight.flatMap { weights.contains($0) ? $0 : nil } ?? weights.last

    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        header(history: history)
        ProgressPeriodPicker(selection: $period)

        if days.isEmpty {
          ContentUnavailableView("Nessuna seduta nel periodo", systemImage: "chart.xyaxis.line",
            description: Text("Scegli un periodo più ampio o completa una seduta con questo esercizio. Le vecchie sedute senza dettaglio non compaiono nei grafici."))
        } else {
          if days.contains(where: { $0.missingWeightCount > 0 }) {
            Label("Le serie senza carico registrato contano per serie e ripetizioni. Carico e volume usano solo i pesi disponibili.",
              systemImage: "info.circle")
              .font(.caption).foregroundStyle(.secondary)
          }

          ProgressChartView(days: days, metric: .maxWeight, onInspectDay: { inspect($0, in: days) })
          ProgressChartView(days: days, metric: .volume, onInspectDay: { inspect($0, in: days) })

          DisclosureGroup {
            VStack(alignment: .leading, spacing: 18) {
              if let weight {
                HStack {
                  Text("Carico da confrontare").font(.subheadline)
                  Spacer()
                  Picker("Carico", selection: Binding(
                    get: { weight }, set: { selectedWeight = $0 }
                  )) {
                    ForEach(weights, id: \.self) { value in
                      Text(ProgressMetric.maxWeight.formatted(value)).tag(value)
                    }
                  }
                  .pickerStyle(.menu)
                }
                ProgressChartView(days: days, metric: .repsAtWeight, weight: weight,
                  onInspectDay: { inspect($0, in: days) })
              } else {
                Text("Registra un carico per confrontare le ripetizioni allo stesso peso.")
                  .font(.caption).foregroundStyle(.secondary)
              }
              Picker("Quantità di lavoro", selection: $quantityMetric) {
                Text("Serie").tag(ProgressMetric.sets)
                Text("Ripetizioni").tag(ProgressMetric.reps)
              }
              .pickerStyle(.segmented)
              ProgressChartView(days: days, metric: quantityMetric,
                onInspectDay: { inspect($0, in: days) })
            }
            .padding(.top, 18)
          } label: {
            Label("Ripetizioni e serie", systemImage: "slider.horizontal.3")
              .font(.headline)
          }

          ExerciseDayComparisonView(days: days)

          VStack(alignment: .leading, spacing: 14) {
            Text("Le tue giornate").font(.title3.bold())
            Text("Apri una giornata per ritrovare tutte le sedute e le serie.")
              .font(.caption).foregroundStyle(.secondary)
            ForEach(days.reversed()) { day in
              Button { inspectedDay = day } label: {
                HStack(spacing: 14) {
                  VStack(alignment: .leading, spacing: 5) {
                    Text(day.date, format: .dateTime.day().month(.abbreviated).year())
                      .font(.subheadline.weight(.semibold))
                    Text("\(day.sessions.count == 1 ? "1 seduta" : "\(day.sessions.count) sedute") · \(day.sets.count) serie · \(day.totalReps) rip.")
                      .font(.caption).foregroundStyle(.secondary)
                  }
                  Spacer(minLength: 0)
                  if day.isWeightRecord {
                    Image(systemName: "trophy.fill").foregroundStyle(.orange)
                      .accessibilityLabel("Nuovo record di carico")
                  }
                  Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .padding(20)
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .foregroundStyle(themeManager.currentTheme.textColor)
    .tint(themeManager.currentTheme.primaryColor)
    .navigationTitle("Progressi")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $inspectedDay) { day in
      NavigationStack {
        List {
          Section {
            Text(exercise.name).font(.headline)
            Text(day.date, format: .dateTime.day().month(.wide).year())
          }
          ForEach(day.sessions) { session in
            Section(session.date.formatted(.dateTime.hour().minute())) {
              WorkoutSetHistoryRows(sets: session.sets)
            }
          }
        }
        .navigationTitle("Serie completate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Fine") { inspectedDay = nil }
          }
        }
      }
    }
  }

  private func inspect(_ date: Date, in days: [ExerciseProgressDay]) {
    inspectedDay = days.first { $0.date == date }
  }

  private func header(history: ExerciseProgressHistory?) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Label(exercise.primaryMuscle.rawValue.uppercased(), systemImage: exercise.primaryMuscle.iconName)
        .font(.caption.weight(.bold))
        .tracking(1)
        .foregroundStyle(themeManager.currentTheme.primaryColor)
      Text(exercise.name)
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      HStack(spacing: 8) {
        Image(systemName: "trophy.fill").foregroundStyle(.orange)
        Text("Miglior carico di sempre")
          .foregroundStyle(.secondary)
        Spacer()
        Text(ProgressMetric.maxWeight.formatted(history?.days.compactMap(\.maxWeight).max()))
          .fontWeight(.semibold)
      }
      .font(.caption)
      .padding(14)
      .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
  }
}

private struct ExerciseDayComparisonView: View {
  let days: [ExerciseProgressDay]
  @State private var firstDate: Date?
  @State private var secondDate: Date?

  private var first: ExerciseProgressDay? {
    days.first { $0.date == firstDate } ?? days.dropLast().last
  }

  private var second: ExerciseProgressDay? {
    days.first { $0.date == secondDate } ?? days.last
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Label("Confronta due giorni", systemImage: "arrow.left.arrow.right")
        .font(.headline)

      if let first, let second, days.count >= 2 {
        HStack {
          datePicker("Da", selection: Binding(get: { first.date }, set: { firstDate = $0 }), excluding: second.date)
          Spacer(minLength: 8)
          Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
          Spacer(minLength: 8)
          datePicker("A", selection: Binding(get: { second.date }, set: { secondDate = $0 }), excluding: first.date)
        }
        ForEach([ProgressMetric.maxWeight, .volume, .sets, .reps]) { metric in
          comparisonRow(metric, first: first, second: second)
        }

        Text("Le differenze descrivono carico e quantità di lavoro; più volume può dipendere da più serie.")
          .font(.caption).foregroundStyle(.secondary)

        DisclosureGroup("Confronta le serie") {
          VStack(alignment: .leading, spacing: 12) {
            Text("Serie nell’ordine di esecuzione, raggruppate per seduta.")
              .font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 16) {
              setColumn(first)
              Divider()
              setColumn(second)
            }
          }
          .padding(.top, 12)
        }
        .font(.subheadline.weight(.medium))
      } else {
        Text("Servono almeno due giornate nel periodo selezionato. Ogni seduta costruisce il prossimo confronto.")
          .font(.subheadline).foregroundStyle(.secondary)
      }
    }
    .progressCard()
    .onChange(of: days.map(\.date)) {
      firstDate = nil
      secondDate = nil
    }
  }

  private func datePicker(_ title: String, selection: Binding<Date>, excluding: Date) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Menu {
        ForEach(days.filter { $0.date != excluding }) { day in
          Button { selection.wrappedValue = day.date } label: {
            if selection.wrappedValue == day.date {
              Label(day.date.formatted(.dateTime.day().month(.abbreviated).year()), systemImage: "checkmark")
            } else {
              Text(day.date, format: .dateTime.day().month(.abbreviated).year())
            }
          }
        }
      } label: {
        HStack(spacing: 4) {
          VStack(alignment: .leading, spacing: 2) {
            Text(selection.wrappedValue, format: .dateTime.day().month(.abbreviated))
              .font(.subheadline.weight(.semibold))
            Text(selection.wrappedValue, format: .dateTime.year())
              .font(.caption)
          }
          Image(systemName: "chevron.up.chevron.down").font(.caption2)
        }
      }
      .accessibilityLabel("\(title), \(selection.wrappedValue.formatted(date: .abbreviated, time: .omitted))")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func comparisonRow(_ metric: ProgressMetric, first: ExerciseProgressDay, second: ExerciseProgressDay) -> some View {
    let old = metric.value(for: first)
    let new = metric.value(for: second)
    return VStack(alignment: .leading, spacing: 8) {
      Divider()
      HStack(alignment: .firstTextBaseline) {
        Text(metric.rawValue).font(.subheadline.weight(.semibold))
        Spacer()
        VStack(alignment: .trailing, spacing: 3) {
          Text(metric.change(from: old, to: new) ?? "Non confrontabile")
          if metric == .volume, let percentage = metric.percentageChange(from: old, to: new) {
            Text(percentage)
          }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
      }
      HStack {
        Text(metric.formatted(old)).frame(maxWidth: .infinity, alignment: .leading)
        Text(metric.formatted(new)).frame(maxWidth: .infinity, alignment: .trailing)
      }
      .font(.system(.subheadline, design: .rounded, weight: .medium))
      .monospacedDigit()
    }
    .accessibilityElement(children: .combine)
  }

  private func setColumn(_ day: ExerciseProgressDay) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(day.date, format: .dateTime.day().month(.abbreviated)).font(.caption.bold())
      ForEach(day.sessions) { session in
        Text(session.date, format: .dateTime.hour().minute())
          .font(.caption2).foregroundStyle(.secondary)
        ForEach(Array(session.sets.enumerated()), id: \.offset) { index, set in
          Text("\(index + 1).  \(ProgressMetric.maxWeight.formatted(set.targetWeight)) × \(set.targetReps)")
            .font(.caption.monospacedDigit())
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
