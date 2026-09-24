import Foundation

/// Determina posizioni valide e prevedibili sui ripiani.
nonisolated struct ShelfPlacementPolicy {
    /// Numero nominale di slot orizzontali su ciascun ripiano.
    static let slotsPerShelf = 4

    /// Incremento di profondità per uno slot riutilizzato.
    static let depthIncrement = 0.15

    /// Suggerisce una posizione sul ripiano meno occupato e nel primo slot libero.
    ///
    /// - Parameters:
    ///   - location: Collocazione a cui appartiene la posizione.
    ///   - occupied: Posizioni già occupate nella collocazione.
    /// - Returns: Posizione valida senza valori sentinella.
    static func autoPlace(location: StorageLocation, occupied: [ShelfPlacement]) -> ShelfPlacement {
        let normalized = occupied.map { clamped($0, location: location) }
        let shelfIndex = leastOccupiedShelf(in: normalized, location: location)
        let placementsOnShelf = normalized.filter { $0.shelfIndex == shelfIndex }

        if let slot = firstFreeSlot(in: placementsOnShelf) {
            return ShelfPlacement(
                shelfIndex: shelfIndex,
                xFraction: center(of: slot),
                depth: 0
            )
        }

        let slot = leastOccupiedSlot(in: placementsOnShelf)
        let depths = placementsOnShelf
            .filter { slotIndex(for: $0.xFraction) == slot }
            .map(\.depth)
        let currentDepth = depths.max() ?? 0

        return ShelfPlacement(
            shelfIndex: shelfIndex,
            xFraction: center(of: slot),
            depth: min(currentDepth + depthIncrement, 1)
        )
    }

    /// Limita una posizione ai confini validi della collocazione.
    ///
    /// - Parameters:
    ///   - placement: Posizione da normalizzare.
    ///   - location: Collocazione che determina il numero di ripiani.
    /// - Returns: Posizione con indice e frazioni nell'intervallo consentito.
    static func clamped(_ placement: ShelfPlacement, location: StorageLocation) -> ShelfPlacement {
        let maximumShelfIndex = location.defaultShelfCount - 1
        return ShelfPlacement(
            shelfIndex: min(max(placement.shelfIndex, 0), maximumShelfIndex),
            xFraction: min(max(placement.xFraction, 0), 1),
            depth: min(max(placement.depth, 0), 1)
        )
    }

    private static func leastOccupiedShelf(in placements: [ShelfPlacement], location: StorageLocation) -> Int {
        let shelfIndices = Array(0..<location.defaultShelfCount)
        return shelfIndices.min { lhs, rhs in
            let lhsCount = placements.count { $0.shelfIndex == lhs }
            let rhsCount = placements.count { $0.shelfIndex == rhs }
            if lhsCount != rhsCount {
                return lhsCount < rhsCount
            }
            return lhs < rhs
        } ?? 0
    }

    private static func firstFreeSlot(in placements: [ShelfPlacement]) -> Int? {
        let occupiedSlots = Set(placements.map { slotIndex(for: $0.xFraction) })
        return (0..<slotsPerShelf).first { !occupiedSlots.contains($0) }
    }

    private static func leastOccupiedSlot(in placements: [ShelfPlacement]) -> Int {
        let slots = Array(0..<slotsPerShelf)
        return slots.min { lhs, rhs in
            let lhsCount = placements.count { slotIndex(for: $0.xFraction) == lhs }
            let rhsCount = placements.count { slotIndex(for: $0.xFraction) == rhs }
            if lhsCount != rhsCount {
                return lhsCount < rhsCount
            }
            return lhs < rhs
        } ?? 0
    }

    private static func center(of slot: Int) -> Double {
        (Double(slot) + 0.5) / Double(slotsPerShelf)
    }

    private static func slotIndex(for xFraction: Double) -> Int {
        let unclampedIndex = Int(xFraction * Double(slotsPerShelf))
        return min(max(unclampedIndex, 0), slotsPerShelf - 1)
    }
}
