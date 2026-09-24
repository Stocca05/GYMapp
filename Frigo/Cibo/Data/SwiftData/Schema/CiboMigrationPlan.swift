import SwiftData

/// Definisce il piano di migrazione iniziale, privo di stadi.
enum CiboMigrationPlan: SchemaMigrationPlan {
    /// Versioni gestite dal piano.
    static var schemas: [any VersionedSchema.Type] { [CiboSchemaV1.self, CiboSchemaV2.self, CiboSchemaV3.self, CiboSchemaV4.self] }
    /// Stadi di migrazione fra versioni.
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: CiboSchemaV1.self, toVersion: CiboSchemaV2.self),
            .lightweight(fromVersion: CiboSchemaV2.self, toVersion: CiboSchemaV3.self),
            .lightweight(fromVersion: CiboSchemaV3.self, toVersion: CiboSchemaV4.self)
        ]
    }
}
