import Foundation
import Observation

/// Mantiene lo stato osservabile degli scaffali senza conoscere SwiftData.
@MainActor @Observable final class FridgeViewModel {
    let inventory: any InventoryRepository
    private(set) var snapshot: InventorySnapshot? {
        didSet { updateGroups() }
    }
    private(set) var errorMessage: String?
    var selectedLocation = StorageLocation.fridge {
        didSet { updateGroups() }
    }
    private(set) var isMoving = false
    private(set) var moveNotice: String?
    private(set) var movedLocation: StorageLocation?

    /// Crea il ViewModel con il repository iniettato.
    init(inventory: any InventoryRepository) { self.inventory = inventory }

    /// Avvia l'osservazione multicast dello snapshot.
    func observe() async {
        do { snapshot = try await inventory.snapshot() }
        catch { errorMessage = "Non riesco a caricare gli alimenti. Riprova."; return }
        errorMessage = nil
        let stream = await inventory.observe()
        for await value in stream {
            guard Task.isCancelled == false else { return }
            if value.revision >= (snapshot?.revision ?? 0) { snapshot = value }
        }
    }

    /// Trasferisce la selezione e aggiorna l'elenco senza cambiare la sezione in uso.
    func move(_ ids: [StockItemID], to location: StorageLocation) async -> Bool {
        guard !isMoving, !ids.isEmpty else { return false }
        isMoving = true
        errorMessage = nil
        defer { isMoving = false }
        do {
            try await inventory.move(ids, to: location)
        } catch {
            errorMessage = "Spostamento non riuscito. Le confezioni potrebbero essere cambiate: controlla la selezione e riprova."
            return false
        }
        // Il salvataggio è già riuscito: un errore di rilettura non deve suggerire di ripeterlo.
        if let updated = try? await inventory.snapshot() { snapshot = updated }
        moveNotice = "\(ids.count) \(ids.count == 1 ? "elemento spostato" : "elementi spostati") in \(location.displayName)"
        movedLocation = location
        return true
    }


    /// Consuma rapidamente un'unità (o passo base) dalla confezione specificata.
    func quickConsumeOne(item: StockItemSnapshot) async -> Bool {
        guard !isMoving else { return false }
        let quantityToConsume = min(item.currentQuantity, item.key.unit.defaultStep)
        isMoving = true
        defer { isMoving = false }
        do {
            try await inventory.consume(item.id, quantity: quantityToConsume)
        } catch {
            errorMessage = "Impossibile consumare l'alimento: riprova."
            return false
        }
        await refreshAfterConsumption()
        return true
    }

    /// Consuma rapidamente un'unità dalla confezione più vicina alla scadenza all all'apertura nel gruppo specificato.
    func quickConsumeOne(from group: StockGroup) async -> Bool {
        guard !isMoving else { return false }
        let item = group.representative

        let quantityToConsume = min(item.currentQuantity, item.key.unit.defaultStep)
        isMoving = true
        defer { isMoving = false }
        do {
            try await inventory.consume(item.id, quantity: quantityToConsume)
        } catch {
            errorMessage = "Impossibile consumare l'alimento: riprova."
            return false
        }
        await refreshAfterConsumption()
        return true
    }


    /// Butta o rimuove interamente la confezione specificata.
    func discardWhole(item: StockItemSnapshot) async -> Bool {
        guard !isMoving else { return false }
        isMoving = true
        defer { isMoving = false }
        do {
            try await inventory.consume(item.id, quantity: item.currentQuantity)
        } catch {
            errorMessage = "Errore durante la rimozione dell'alimento."
            return false
        }
        await refreshAfterConsumption()
        return true
    }

    /// Butta o rimuove interamente la confezione più vicina alla scadenza.
    func discardWhole(from group: StockGroup) async -> Bool {
        guard !isMoving else { return false }
        let item = group.representative

        isMoving = true
        defer { isMoving = false }
        do {
            try await inventory.consume(item.id, quantity: item.currentQuantity)
        } catch {
            errorMessage = "Errore durante la rimozione dell'alimento."
            return false
        }
        await refreshAfterConsumption()
        return true
    }



    /// Chiude il riscontro dell'ultimo trasferimento.
    func clearNotice() { moveNotice = nil; movedLocation = nil }

    /// Azzera un errore già letto dall'utente.
    func clearError() { errorMessage = nil }

    /// Aggiorna la scorta dopo un consumo già salvato, senza suggerire di ripeterlo.
    func refreshAfterConsumption() async {
        if let updated = try? await inventory.snapshot() { snapshot = updated }
        clearNotice()
    }

    /// Restituisce i gruppi visibili nella location selezionata.
    private(set) var groups: [StockGroup] = []

    private func updateGroups() {
        groups = ShelfGrouping.group(items: snapshot?.items(in: selectedLocation) ?? [])
    }
}
