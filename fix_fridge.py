import re

with open("Frigo/Cibo/Features/Fridge/FridgeViewModel.swift", "r") as f:
    text = f.read()

func1 = """
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

"""

func2 = """
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

"""

if "func quickConsumeOne(item:" not in text:
    text = text.replace("    /// Consuma rapidamente un'unità dalla confezione più vicina", func1 + "    /// Consuma rapidamente un'unità dalla confezione più vicina")

if "func discardWhole(item:" not in text:
    text = text.replace("    /// Butta o rimuove interamente la confezione più vicina", func2 + "    /// Butta o rimuove interamente la confezione più vicina")

with open("Frigo/Cibo/Features/Fridge/FridgeViewModel.swift", "w") as f:
    f.write(text)
