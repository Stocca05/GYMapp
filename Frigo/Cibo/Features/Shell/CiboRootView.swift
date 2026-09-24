import SwiftUI

/// Costituisce il punto d'ingresso del modulo Cibo nell'app host.
struct CiboRootView: View {
    @State private var viewModel: FridgeViewModel?
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            Group {
                if let failure {
                    ContentUnavailableView("Cibo non disponibile", systemImage: "exclamationmark.triangle", description: Text(failure))
                } else if let viewModel {
                    FoodMainContainer(viewModel: viewModel, inventory: viewModel.inventory, subjectExtractor: ResilientSubjectExtractor(primary: VisionSubjectExtractor(), fallback: PassthroughSubjectExtractor()))
                } else {
                    ProgressView("Caricamento del frigo…")
                }
            }
            .navigationTitle("Cibo")
        }
        .task { await bootstrap() }
    }

    /// Inizializza lo store isolato e carica il primo snapshot.
    @MainActor private func bootstrap() async {
        guard viewModel == nil else { return }
        do {
            let container = try CiboContainerFactory.make(inMemory: false)
            let store = try await SwiftDataInventoryStore.makeOffMainActor(modelContainer: container, dateProvider: SystemDateProvider(), calendar: .current)
            viewModel = FridgeViewModel(inventory: store)
        } catch { failure = String(describing: error) }
    }
}
