new_code = """import SwiftUI
import Charts

struct GymCalendarView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if workoutManager.completedSessions.isEmpty {
                        emptyStateView
                    } else {
                        vanityMetricsPanel
                        
                        chartSection
                        
                        logbookSection
                    }
                }
                .padding(.vertical, 24)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Analisi & Storico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { closeButton } }
        }
    }
    
    // MARK: - Components
    
    private var vanityMetricsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trofei e Traguardi")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.textColor)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Total Volume
                    let totalVol = workoutManager.completedSessions.reduce(0) { $0 + $1.totalVolume }
                    vanityCard(
                        title: "Totale Mosso",
                        value: "\\(totalVol) KG",
                        subtitle: "Pari a \\(totalVol / 1500) utilitarie!",
                        icon: "car.fill",
                        color: .blue
                    )
                    
                    // Max Session
                    let maxVol = workoutManager.completedSessions.map({ $1.totalVolume }).max() ?? 0
                    vanityCard(
                        title: "Miglior Seduta",
                        value: "\\(maxVol) KG",
                        subtitle: "Il tuo picco massimo",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    // Total Time
                    let totalSeconds = workoutManager.completedSessions.reduce(0) { $0 + $1.durationSeconds }
                    let hours = totalSeconds / 3600
                    vanityCard(
                        title: "Tempo Sotto Ghisa",
                        value: "\\(hours) Ore",
                        subtitle: "Di pura dedizione",
                        icon: "clock.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func vanityCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.textColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
            }
        }
        .padding(16)
        .frame(width: 160, height: 160)
        .background(themeManager.currentTheme.primaryColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.currentTheme.primaryColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Evoluzione di Forza (Volume)")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.textColor)
                .padding(.horizontal, 24)
            
            // Sort by date inside the view logic
            let sorted = workoutManager.completedSessions.sorted(by: { $0.date < $1.date })
            
            Chart {
                ForEach(sorted, id: \\.id) { session in
                    LineMark(
                        x: .value("Data", session.date),
                        y: .value("KG", session.totalVolume)
                    )
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                    .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom) // Rende la linea curva e sensuale
                    
                    AreaMark(
                        x: .value("Data", session.date),
                        y: .value("KG", session.totalVolume)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.currentTheme.primaryColor.opacity(0.4),
                                themeManager.currentTheme.primaryColor.opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Data", session.date),
                        y: .value("KG", session.totalVolume)
                    )
                    .foregroundStyle(themeManager.currentTheme.backgroundColor)
                    .symbolSize(100)
                    
                    PointMark(
                        x: .value("Data", session.date),
                        y: .value("KG", session.totalVolume)
                    )
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                    .symbolSize(40)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(themeManager.currentTheme.secondaryColor.opacity(0.2))
                    AxisValueLabel() {
                        if let kg = value.as(Int.self) {
                            Text("\\(kg)k").font(.caption2.bold()).foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.caption2.bold())
                        .foregroundStyle(themeManager.currentTheme.secondaryColor)
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 16)
        }
    }
    
    private var logbookSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diario di Bordo")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.textColor)
                .padding(.horizontal, 24)
            
            LazyVStack(spacing: 12) {
                // Più recenti in alto
                ForEach(workoutManager.completedSessions.sorted(by: { $0.date > $1.date })) { session in
                    let planName = workoutManager.myPlans.first(where: { $0.id == session.planId })?.title ?? "Scheda Rimossa"
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(planName)
                                .font(.subheadline.bold())
                                .foregroundStyle(themeManager.currentTheme.textColor)
                            Text(session.date, format: .dateTime.day().month().year().hour().minute())
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("\\(session.totalVolume) KG")
                                .font(.system(.body, design: .rounded).weight(.black))
                                .foregroundStyle(themeManager.currentTheme.primaryColor)
                            
                            let mins = session.durationSeconds / 60
                            Text("\\(mins) Minuti")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                    }
                    .padding(16)
                    .background(themeManager.currentTheme.primaryColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                .padding(.top, 100)
            
            Text("Nessun dato")
                .font(.title2.bold())
                .foregroundStyle(themeManager.currentTheme.textColor)
            
            Text("Completa il tuo primo allenamento per sbloccare le analisi di progressione.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                .padding(.horizontal, 40)
        }
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                .font(.title3)
        }
    }
}
"""

with open("Frigo/Allenamento/Views/GymCalendarView.swift", "w") as f:
    f.write(new_code)
