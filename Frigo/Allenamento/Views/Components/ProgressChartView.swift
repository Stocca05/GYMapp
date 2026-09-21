import Charts
import SwiftUI

struct ProgressPeriodPicker: View {
  @Binding var selection: ProgressPeriod

  var body: some View {
    Picker("Periodo", selection: $selection) {
      ForEach(ProgressPeriod.allCases) { period in
        Text(period.rawValue).tag(period)
      }
    }
    .pickerStyle(.segmented)
  }
}

private struct ProgressCardStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(20)
      .background(Color(uiColor: .secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 24))
      .overlay {
        RoundedRectangle(cornerRadius: 24)
          .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.025), radius: 12, y: 5)
  }
}

extension View {
  func progressCard() -> some View { modifier(ProgressCardStyle()) }
}

struct ProgressChartPoint: Identifiable {
  let date: Date
  let value: Double
  var id: Date { date }
}

struct ProgressChartView: View {
  @Environment(ThemeManager.self) private var themeManager
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var selectedDate: Date?

  let days: [ExerciseProgressDay]
  let metric: ProgressMetric
  var weight: Double? = nil
  var onInspectDay: ((Date) -> Void)? = nil

  private var color: Color {
    switch metric {
    case .maxWeight: return themeManager.currentTheme.primaryColor
    case .volume: return .teal
    case .repsAtWeight: return .purple
    case .sets, .reps: return .orange
    }
  }

  private var points: [ProgressChartPoint] {
    days.compactMap { day in
      metric.value(for: day, weight: weight).map { ProgressChartPoint(date: day.date, value: $0) }
    }
  }

  private var focusedPoint: ProgressChartPoint? {
    guard let selectedDate else { return points.last }
    let target = metric.usesBars ? Calendar.current.startOfDay(for: selectedDate) : selectedDate
    return points.min { abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target)) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      let headerLayout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout())
      headerLayout {
        Label(metric.rawValue, systemImage: metric.usesBars ? "chart.bar.fill" : "chart.xyaxis.line")
          .font(.headline)
          .foregroundStyle(color)
        if !dynamicTypeSize.isAccessibilitySize { Spacer() }
        Text(metric.unit)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }

      if let point = focusedPoint {
        VStack(alignment: .leading, spacing: 4) {
          Text(metric.formatted(point.value))
            .font(.system(.title, design: .rounded, weight: .bold))
            .monospacedDigit()
          Text("\(selectedDate == nil ? "Ultimo dato" : "Selezione") · \(point.date.formatted(.dateTime.day().month(.abbreviated).year()))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        chart

        HStack {
          Text("Tocca o scorri sul grafico")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Spacer()
          if let onInspectDay {
            Button { onInspectDay(point.date) } label: {
              Label("Serie", systemImage: "arrow.up.right")
                .font(.caption.weight(.semibold))
            }
            .accessibilityLabel("Mostra le serie del \(point.date.formatted(date: .abbreviated, time: .omitted))")
          }
        }
      } else {
        Label("Nessun dato registrato per questa metrica nel periodo.", systemImage: "chart.xyaxis.line")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 100)
      }

      Text(metric.explanation)
        .font(.caption)
        .foregroundStyle(.secondary)

      if points.count == 1 && !metric.usesBars {
        Text("Il primo punto. La linea apparirà con un’altra giornata registrata.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .progressCard()
    .onChange(of: metric) { selectedDate = nil }
    .onChange(of: weight) { selectedDate = nil }
    .onChange(of: days.map(\.date)) { selectedDate = nil }
  }

  private var chart: some View {
    Chart {
      ForEach(points) { point in
        if metric.usesBars {
          BarMark(x: .value("Giorno", point.date, unit: .day), y: .value(metric.rawValue, point.value))
            .cornerRadius(5)
            .foregroundStyle(color.gradient)
            .opacity(selectedDate == nil || focusedPoint?.id == point.id ? 1 : 0.35)
            .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
            .accessibilityValue(metric.formatted(point.value))
        } else {
          LineMark(x: .value("Giorno", point.date), y: .value(metric.rawValue, point.value))
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(color)
          PointMark(x: .value("Giorno", point.date), y: .value(metric.rawValue, point.value))
            .symbolSize(focusedPoint?.id == point.id ? 65 : 28)
            .foregroundStyle(color)
            .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
            .accessibilityValue(metric.formatted(point.value))
        }
      }
      if selectedDate != nil, let point = focusedPoint {
        RuleMark(x: .value("Selezione", point.date))
          .foregroundStyle(color.opacity(0.3))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
      }
    }
    .chartXScale(domain: dateDomain)
    .chartYScale(domain: 0...max(1, (points.map(\.value).max() ?? 0) * 1.15))
    .chartXSelection(value: $selectedDate)
    .chartGesture { proxy in
      DragGesture(minimumDistance: 0)
        .onChanged { proxy.selectXValue(at: $0.location.x) }
        .onEnded { proxy.selectXValue(at: $0.location.x) }
    }
    .chartLegend(.hidden)
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 3)) {
        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
        AxisGridLine(stroke: StrokeStyle(dash: [3, 4]))
          .foregroundStyle(.secondary.opacity(0.15))
        AxisValueLabel()
      }
    }
    .frame(height: 190)
  }

  private var dateDomain: ClosedRange<Date> {
    let first = points.first?.date ?? Date()
    let last = points.last?.date ?? first
    let calendar = Calendar.current
    let start = calendar.date(byAdding: .day, value: -1, to: first) ?? first
    let end = calendar.date(byAdding: .day, value: 2, to: last) ?? last
    return start...end
  }
}
