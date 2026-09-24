import SwiftData

/// Crea il container SwiftData isolato del modulo Cibo.
enum CiboContainerFactory {
    @MainActor private static var sharedContainer: ModelContainer?

    /// Crea il container Cibo, opzionalmente solo in memoria.
    ///
    /// - Parameter inMemory: Indica se lo store non deve essere persistito su disco.
    /// - Returns: Container configurato con schema e migrazione del modulo.
    /// - Throws: Propaga gli errori di inizializzazione di SwiftData.
    @MainActor static func make(inMemory: Bool) throws -> ModelContainer {
        if !inMemory, let shared = sharedContainer { 
            return shared 
        }
        
        let schema = Schema(versionedSchema: CiboSchemaV4.self)
        let configuration = ModelConfiguration("Cibo", schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CiboMigrationPlan.self, configurations: [configuration])
        
        if !inMemory {
            sharedContainer = container
        }
        return container
    }
}
