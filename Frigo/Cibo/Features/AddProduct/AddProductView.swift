import SwiftUI
import PhotosUI

/// Consente di creare un prodotto o di aggiungere una confezione a un prodotto noto.
struct AddProductView: View {
    let inventory: any InventoryRepository
    let subjectExtractor: any SubjectExtracting
    let defaultLocation: StorageLocation
    @Environment(\.dismiss) private var dismiss
    @State private var catalog: [ProductSnapshot] = []
    @State private var name = ""
    @State private var category = ProductCategory.other
    @State private var unit = UnitOfMeasure.pieces
    @State private var packageCount = 1
    @State private var quantityPerPackage = 1
    @State private var shelfLife = 7
    @State private var hasOpenShelfLife = false
    @State private var openShelfLife = 7
    @State private var location: StorageLocation
    @State private var errorMessage: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingCamera = false
    @State private var isSaving = false

    /// Crea il form usando la location attualmente visibile.
    init(inventory: any InventoryRepository, subjectExtractor: any SubjectExtracting, defaultLocation: StorageLocation) {
        self.inventory = inventory
        self.subjectExtractor = subjectExtractor
        self.defaultLocation = defaultLocation
        _location = State(initialValue: defaultLocation)
    }


    private var normalizedName: String {
        name.normalizedForSearch
    }

    private var knownProduct: ProductSnapshot? {
        let search = normalizedName
        guard !search.isEmpty else { return nil }
        return catalog.first { $0.name.normalizedForSearch == search }
    }


    private var packageTitle: String { displayedUnit == .pieces ? "Pezzi" : "Confezioni" }
    private var displayedQuantityPerPackage: Int { knownProduct?.defaultQuantityPerPackage ?? quantityPerPackage }
    private var displayedUnit: UnitOfMeasure { knownProduct?.baseUnit ?? unit }
    private var total: Int { packageCount * displayedQuantityPerPackage }

    var body: some View {
        NavigationStack {
            Form {
                Section("Prodotto") {
                    TextField("Nome", text: $name)
                        .textInputAutocapitalization(.words)
                }

                if let knownProduct {
                    knownProductSection(knownProduct)
                    quantitySection
                    locationSection
                } else {
                    newProductSetupSection
                    quantitySection
                    shelfLifeSection
                    photoSection
                    locationSection
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .disabled(isSaving)
            .navigationTitle(knownProduct == nil ? "Nuovo prodotto" : "Aggiungi prodotto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Salvataggio…" : "Salva") { Task { await save() } }
                        .disabled(normalizedName.isEmpty || isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .task { await loadCatalog() }
        .onChange(of: photoItem) { _, item in Task { await loadPhoto(item) } }
        .onChange(of: knownProduct?.id) { _, productID in applyKnownProduct(id: productID) }
        .onChange(of: unit) { _, selectedUnit in
            if selectedUnit == .pieces { quantityPerPackage = 1 }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(onImage: { data in
                imageData = data
                showingCamera = false
            }, onCancel: { showingCamera = false })
        }
    }

    private var newProductSetupSection: some View {
        Section("Impostazioni iniziali") {
            Picker("Categoria", selection: $category) {
                ForEach(ProductCategory.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("Unità", selection: $unit) {
                ForEach(UnitOfMeasure.allCases) { Text($0.abbreviation).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func knownProductSection(_ product: ProductSnapshot) -> some View {
        Section {
            HStack(spacing: 12) {
                productImage(product)
                VStack(alignment: .leading, spacing: 3) {
                    Label("Già configurato", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    Text("\(product.category.displayName) · \(product.baseUnit.abbreviation) · \(product.defaultQuantityPerPackage) \(product.baseUnit.abbreviation) per confezione")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(shelfLifeDescription(for: product))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder private func productImage(_ product: ProductSnapshot) -> some View {
        if let data = product.thumbnailPNG, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 54, height: 54)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var quantitySection: some View {
        Section("Quantità") {
            QuantitySelectorView(title: packageTitle, unit: .pieces, maximum: 24, quantity: $packageCount)
            if displayedUnit != .pieces, knownProduct == nil {
                QuantitySelectorView(title: "Quantità per confezione", unit: unit, maximum: 10_000, quantity: $quantityPerPackage)
            }
            LabeledContent("Totale", value: "\(total) \(displayedUnit.abbreviation)")
                .font(.headline)
        }
    }

    private var shelfLifeSection: some View {
        Section("Conservazione") {
            Picker("Durata da chiuso", selection: $shelfLife) {
                ForEach(1...60, id: \.self) { days in Text("\(days) giorni").tag(days) }
            }
            Toggle("Durata dopo l'apertura", isOn: $hasOpenShelfLife)
            if hasOpenShelfLife {
                Picker("Durata da aperto", selection: $openShelfLife) {
                    ForEach(1...60, id: \.self) { days in Text("\(days) giorni").tag(days) }
                }
            }
        }
    }

    private var photoSection: some View {
        Section("Foto") {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(imageData == nil ? "Scegli foto" : "Foto selezionata", systemImage: "photo")
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Scatta foto", systemImage: "camera") { showingCamera = true }
            }
        }
    }

    private var locationSection: some View {
        Section("Dove lo metti?") {
            Picker("Posizione", selection: $location) {
                ForEach(StorageLocation.allCases) { Text($0.displayName).tag($0) }
            }
        }
    }

    private func shelfLifeDescription(for product: ProductSnapshot) -> String {
        let closed = product.defaultShelfLifeDays.map { "Chiuso: \($0) giorni" } ?? "Durata non impostata"
        guard let open = product.openShelfLifeDays else { return closed }
        return "\(closed) · Aperto: \(open) giorni"
    }

    @MainActor private func loadCatalog() async {
        do {
            catalog = try await inventory.snapshot().products
            applyKnownProduct(id: knownProduct?.id)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    @MainActor private func applyKnownProduct(id: ProductID?) {
        guard let id, let product = catalog.first(where: { $0.id == id }) else { return }
        category = product.category
        unit = product.baseUnit
        quantityPerPackage = product.defaultQuantityPerPackage
        shelfLife = product.defaultShelfLifeDays ?? 7
        hasOpenShelfLife = product.openShelfLifeDays != nil
        openShelfLife = product.openShelfLifeDays ?? 7
    }

    @MainActor private func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            if let product = knownProduct {
                _ = try await inventory.addStock(productID: product.id, packageCount: packageCount, location: location)
            } else {
                let processed: ExtractedSubject?
                if let imageData {
                    processed = try await subjectExtractor.extractSubject(from: imageData)
                } else {
                    processed = nil
                }
                _ = try await inventory.addProduct(NewProductDraft(name: name, category: category, baseUnit: unit, packageCount: packageCount, quantityPerPackage: quantityPerPackage, location: location, shelfLifeDays: shelfLife, expirationDate: nil, openShelfLifeDays: hasOpenShelfLife ? openShelfLife : nil, displayScale: 1, imageData: processed?.fullPNG, thumbnailData: processed?.thumbnailPNG))
            }
            dismiss()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    @MainActor private func loadPhoto(_ item: PhotosPickerItem?) async {
        do {
            imageData = try await item?.loadTransferable(type: Data.self)
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

fileprivate extension String {
    var normalizedForSearch: String {
        self.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
