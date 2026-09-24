import SwiftData

/// Definisce lo schema che aggiunge lo storico delle preparazioni.
enum CiboSchemaV4: VersionedSchema {
    /// Identificatore della quarta versione dello schema.
    static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }
    /// Modelli inclusi nella quarta versione dello schema.
    static var models: [any PersistentModel.Type] { [ProductRecord.self, StockItemRecord.self, RecipeRecord.self, RecipeIngredientRecord.self, CookedMealRecord.self, CookedMealIngredientRecord.self] }
}
