import SwiftUI

struct HomeView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    @AppStorage("home.shopping-items") private var savedShoppingItems = "[]"

    @State private var shoppingItems: [ShoppingItem] = []
    @State private var newShoppingItem = ""
    @State private var showingAddShoppingItem = false
    @State private var showingActiveWorkout = false
    @State private var showingWorkoutCreator = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        header
                        dailyFocus
                        todayOverview
                        quickActions
                        shoppingList
                        trainingSnapshot
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(themeManager.currentTheme.primaryColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Apri profilo")
                }
            }
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                WorkoutActiveView()
            }
            .fullScreenCover(isPresented: $showingWorkoutCreator) {
                WorkoutCreatorView()
            }
            .alert("Aggiungi alla spesa", isPresented: $showingAddShoppingItem) {
                TextField("Es. latte, verdure, pasta", text: $newShoppingItem)
                Button("Annulla", role: .cancel) { newShoppingItem = "" }
                Button("Aggiungi") { addShoppingItem() }
            } message: {
                Text("Lo ritroverai nella tua lista della spesa.")
            }
            .task { loadShoppingItems() }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                themeManager.currentTheme.backgroundColor,
                themeManager.currentTheme.primaryColor.opacity(0.055),
                themeManager.currentTheme.backgroundColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text(greeting)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)

                Text("La tua giornata,\nin equilibrio.")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.textColor)
                    .lineSpacing(-3)
            }

            Spacer(minLength: 16)

            VStack(spacing: 5) {
                Text(todayNumber)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(todayMonth)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
            }
            .frame(width: 58, height: 66)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(themeManager.currentTheme.primaryColor.opacity(0.13), lineWidth: 1)
            }
        }
    }

    private var dailyFocus: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("FOCUS DI OGGI", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .tracking(0.7)
                        .foregroundStyle(.white.opacity(0.78))

                    Text(focusTitle)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: workoutManager.ongoingWorkout == nil ? "leaf.fill" : "flame.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.16), in: Circle())
            }

            HStack(spacing: 12) {
                focusMetric(icon: "fork.knife", text: "Pasti sotto controllo")
                focusMetric(icon: "figure.strengthtraining.traditional", text: workoutStatus)
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.primaryColor.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 18, x: 0, y: 11)
        }
    }

    private var todayOverview: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Oggi in breve", detail: Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))

            HStack(spacing: 12) {
                overviewCard(icon: "refrigerator.fill", tint: .teal, value: "Frigo", label: "Organizza la spesa")
                overviewCard(icon: "flame.fill", tint: .orange, value: "\(workoutManager.currentStreak)", label: workoutManager.currentStreak == 1 ? "giorno di fila" : "giorni di fila")
                overviewCard(icon: "bolt.heart.fill", tint: .pink, value: "\(workoutManager.caloriesBurnedToday)", label: "kcal oggi")
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Azioni rapide")

            HStack(spacing: 12) {
                Button(action: startWorkout) {
                    quickAction(
                        icon: workoutManager.ongoingWorkout == nil ? "play.fill" : "figure.run",
                        title: workoutManager.ongoingWorkout == nil ? "Avvia scheda" : "Riprendi scheda",
                        subtitle: workoutManager.ongoingWorkout == nil ? nextPlanTitle : "Allenamento in corso",
                        tint: .orange
                    )
                }
                .buttonStyle(.plain)

                Button { showingAddShoppingItem = true } label: {
                    quickAction(
                        icon: "cart.badge.plus",
                        title: "Aggiungi spesa",
                        subtitle: shoppingItems.isEmpty ? "Crea la tua lista" : "\(remainingShoppingCount) da comprare",
                        tint: .teal
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                NavigationLink(destination: FoodView()) {
                    Label("Il mio frigo", systemImage: "refrigerator.fill")
                }
                NavigationLink(destination: GymView()) {
                    Label("Area palestra", systemImage: "dumbbell.fill")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(themeManager.currentTheme.primaryColor)
        }
    }

    private var shoppingList: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("Lista della spesa")
                Spacer()
                Button("Aggiungi", systemImage: "plus") { showingAddShoppingItem = true }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }

            if shoppingItems.isEmpty {
                emptyShoppingList
            } else {
                VStack(spacing: 0) {
                    ForEach(shoppingItems) { item in
                        shoppingRow(item)
                        if item.id != shoppingItems.last?.id {
                            Divider().padding(.leading, 45)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private var emptyShoppingList: some View {
        HStack(spacing: 14) {
            Image(systemName: "basket.fill")
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 44, height: 44)
                .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("La lista è pronta")
                    .font(.subheadline.bold())
                Text("Aggiungi quello che ti serve per la prossima spesa.")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var trainingSnapshot: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Il tuo ritmo", detail: "Questa settimana")

            HStack(spacing: 8) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    let isComplete = workoutManager.currentWeekStatus[index]
                    VStack(spacing: 9) {
                        Text(day)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        Circle()
                            .fill(isComplete ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.primaryColor.opacity(0.12))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if isComplete {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func quickAction(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(colors: [tint, tint.opacity(0.68)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .shadow(color: tint.opacity(0.22), radius: 10, x: 0, y: 6)
    }

    private func shoppingRow(_ item: ShoppingItem) -> some View {
        HStack(spacing: 12) {
            Button { toggleShoppingItem(item) } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPurchased ? .teal : themeManager.currentTheme.secondaryColor.opacity(0.55))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isPurchased ? "Segna \(item.name) come da comprare" : "Segna \(item.name) come acquistato")

            Text(item.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(item.isPurchased ? themeManager.currentTheme.secondaryColor : themeManager.currentTheme.textColor)
                .strikethrough(item.isPurchased, color: themeManager.currentTheme.secondaryColor)

            Spacer()

            Button(role: .destructive) { removeShoppingItem(item) } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rimuovi \(item.name) dalla lista")
        }
        .padding(.vertical, 12)
    }

    private func startWorkout() {
        if workoutManager.ongoingWorkout != nil {
            showingActiveWorkout = true
        } else if let plan = workoutManager.suggestedWorkoutForToday() {
            workoutManager.startOrResumeWorkout(plan: plan)
            showingActiveWorkout = true
        } else {
            showingWorkoutCreator = true
        }
    }

    private func loadShoppingItems() {
        guard let data = savedShoppingItems.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) else { return }
        shoppingItems = decoded
    }

    private func saveShoppingItems() {
        guard let data = try? JSONEncoder().encode(shoppingItems),
              let encoded = String(data: data, encoding: .utf8) else { return }
        savedShoppingItems = encoded
    }

    private func addShoppingItem() {
        let itemName = newShoppingItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemName.isEmpty else { return }
        shoppingItems.insert(ShoppingItem(name: itemName), at: 0)
        newShoppingItem = ""
        saveShoppingItems()
    }

    private func toggleShoppingItem(_ item: ShoppingItem) {
        guard let index = shoppingItems.firstIndex(where: { $0.id == item.id }) else { return }
        shoppingItems[index].isPurchased.toggle()
        saveShoppingItems()
    }

    private func removeShoppingItem(_ item: ShoppingItem) {
        shoppingItems.removeAll { $0.id == item.id }
        saveShoppingItems()
    }

    private func focusMetric(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.16), in: Capsule())
    }

    private func overviewCard(icon: String, tint: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.currentTheme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .frame(minHeight: 126)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func sectionTitle(_ title: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(themeManager.currentTheme.textColor)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
            }
        }
    }

    private var greeting: String {
        switch calendar.component(.hour, from: Date()) {
        case 5..<12: "Buongiorno"
        case 12..<18: "Buon pomeriggio"
        default: "Buonasera"
        }
    }

    private var focusTitle: String {
        if workoutManager.ongoingWorkout != nil { return "Sei già nel flow.\nContinua così." }
        if workoutManager.currentStreak > 0 { return "Una piccola scelta\nper stare bene." }
        return "Cura ciò che conta,\nun gesto alla volta."
    }

    private var workoutStatus: String {
        workoutManager.ongoingWorkout == nil ? "Pronto quando vuoi" : "Allenamento in corso"
    }

    private var nextPlanTitle: String {
        workoutManager.suggestedWorkoutForToday()?.title ?? "Crea la prima scheda"
    }

    private var remainingShoppingCount: Int {
        shoppingItems.filter { !$0.isPurchased }.count
    }

    private var todayNumber: String { Date.now.formatted(.dateTime.day()) }
    private var todayMonth: String { Date.now.formatted(.dateTime.month(.abbreviated)) }
    private var weekDays: [String] { ["L", "M", "M", "G", "V", "S", "D"] }
}

private struct ShoppingItem: Identifiable, Codable {
    let id: UUID
    let name: String
    var isPurchased: Bool

    init(id: UUID = UUID(), name: String, isPurchased: Bool = false) {
        self.id = id
        self.name = name
        self.isPurchased = isPurchased
    }
}

#Preview {
    HomeView()
        .environment(ThemeManager())
        .environment(WorkoutManager())
}
