# Architettura del modulo Cibo

## Scopo e struttura

Il modulo Cibo è isolato in `Frigo/Cibo/`. Il target host lo compila tramite la cartella sincronizzata `Frigo/`; non esistono dipendenze esterne.

```
Cibo/
├── Domain/
│   ├── Model/
│   ├── Rules/
│   └── Ports/
├── Data/
│   └── SwiftData/
├── Services/
│   ├── Imaging/
│   └── Vision/
├── Features/
│   ├── Shell/
│   ├── Fridge/
│   └── AddProduct/
├── Support/
├── Tools/
└── Docs/
```

`Domain` importa esclusivamente Foundation. Contiene value type `Sendable`, errori tipizzati, protocolli dei port e regole pure. `Data` contiene gli unici tipi `@Model`, lo store SwiftData e le implementazioni in memoria. Le istanze `@Model` non escono mai da questo layer.

`Services` adatta API di piattaforma, fra cui Vision, ImageIO e haptics UIKit, ai port del Domain. `Features` contiene View SwiftUI e ViewModel `@MainActor @Observable`; dipende dai soli protocolli Domain. Solo `Features/Shell` è la composition root e può conoscere implementazioni concrete di Data e Services.

## Regola di dipendenza

Le dipendenze procedono verso Domain: Features e Services dipendono da Domain; Data dipende da Domain e SwiftData; Shell compone Data, Services e Features. Nessun layer inferiore importa Features. Nessuna Feature, esclusa Shell, importa SwiftData, Vision o CoreImage, né usa un tipo concreto dichiarato in Data o Services.

## Flusso dei dati

Il flusso è unidirezionale:

```
View → ViewModel → Repository → actor SwiftData
                                  │
                      valida → muta → un save o rollback
                                  │
View ← ViewModel ← AsyncStream ← snapshot Sendable
```

Una View rimane sottile e non usa `@Query` o `ModelContext`. Il ViewModel riceve il repository dal costruttore, osserva snapshot immutabili con `AsyncStream` e aggiorna lo stato della View sul main actor. Per ogni comando il repository valida, applica le mutazioni e invoca un solo `save()`; a fronte di errore invoca `rollback()` e propaga un errore tipizzato.

## Concorrenza e confini

Tra layer e tra isolamenti passano esclusivamente value type `Sendable`: snapshot, draft, richieste e risultati. Non passano né `@Model` né `UIImage`. Un solo actor possiede il `ModelContext` e costituisce l'unico scrittore. Le operazioni CPU-bound di Vision e CoreImage sono eseguite fuori dal main actor; le ViewModel restano `@MainActor`.

Date, Calendar e ogni altra dipendenza necessaria alle regole vengono iniettati. Le regole del Domain sono deterministiche e prive di I/O.

## Convenzioni di naming

I nomi di file, tipi, membri e messaggi tecnici sono in inglese. Commenti e DocString sono in italiano. Un file contiene un tipo principale e resta sotto 300 righe, salvo ADR motivato. Ogni tipo o funzione non `private` ha una DocString in italiano; include `Parameters`, `Returns` e `Throws` quando applicabili.

Le quantità sono `Int` nell'unità base: grammi (`g`), millilitri (`ml`) o pezzi (`pcs`). Non si usano `Double` per quantità. Le ViewModel terminano con `ViewModel`, i repository con `Repository`, gli snapshot con `Snapshot`, i draft con `Draft`, le richieste con `Request` e gli errori con `Error`.

## Glossario del dominio

| Termine | Significato |
| --- | --- |
| Product | Descrizione catalografica di un alimento. |
| Inventory item | Un lotto fisico conservato nel frigorifero. |
| Stock | Quantità disponibile di un inventory item. |
| StockKey | Chiave di aggregazione composta da category e unit. |
| Category | Categoria merceologica del prodotto. |
| Unit | Unità base della quantità: g, ml o pcs. |
| Expiry date | Data di scadenza del lotto. |
| Shelf position | Posizione visuale composta da shelfIndex, xFraction e depth. |
| Lifecycle | Stato di un lotto: active, consumed o discarded. |
