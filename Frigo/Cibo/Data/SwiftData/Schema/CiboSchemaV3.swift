import SwiftData

/// Definisce lo schema che aggiunge le ricette personali e i loro ingredienti.
enum CiboSchemaV3: VersionedSchema {
    /// Identificatore della terza versione dello schema.
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }
    /// Modelli inclusi nella terza versione dello schema.
    static var models: [any PersistentModel.Type] { [ProductRecord.self, StockItemRecord.self, RecipeRecord.self, RecipeIngredientRecord.self] }
}
