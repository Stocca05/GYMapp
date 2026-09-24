# Decisioni architetturali

## ADR 001 — Snapshot Sendable e unico scrittore

**Contesto** · Le View non devono accedere direttamente a SwiftData.

**Decisione** · Il repository invia snapshot immutabili tramite `AsyncStream` e un actor è l'unico proprietario del `ModelContext`.

**Conseguenze** · Il frigorifero osserva dati sicuri senza conoscere la persistenza.

## ADR 002 — Quantità intere e confezioni aggregate

**Contesto** · L'utente inserisce pezzi e quantità per pezzo, ma le disponibilità devono restare esatte.

**Decisione** · Il draft calcola il totale con `pezzi × quantità per pezzo` e lo store conserva esclusivamente quantità intere nella base unit.

**Conseguenze** · L'inserimento è chiaro e i calcoli di disponibilità non introducono decimali.

## ADR 003 — Store SwiftData separato

**Contesto** · Il frigorifero non deve modificare il container dell'app host.

**Decisione** · Il modulo crea uno store SwiftData autonomo senza CloudKit.

**Conseguenze** · Il ciclo di vita dei dati del frigorifero resta isolato.
