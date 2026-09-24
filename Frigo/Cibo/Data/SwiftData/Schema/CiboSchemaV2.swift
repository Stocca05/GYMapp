import SwiftData

/// Definisce lo schema che memorizza la quantità della confezione standard.
enum CiboSchemaV2: VersionedSchema {
    /// Identificatore della seconda versione dello schema.
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    /// Modelli inclusi nella seconda versione dello schema.
    static var models: [any PersistentModel.Type] { [ProductRecord.self, StockItemRecord.self] }
}
