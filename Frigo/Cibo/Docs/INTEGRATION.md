# Integrazione manuale con l'app host

Questo documento raccoglie esclusivamente modifiche manuali richieste fuori da `Frigo/Cibo/`.

## Stato iniziale

`Frigo/` è un gruppo sincronizzato Xcode e i file Swift aggiunti al modulo vengono inclusi automaticamente nel target `Frigo`. Il progetto non contiene un test target.

## Voci future

| Area esterna | Modifica richiesta | Motivo | Stato |
| --- | --- | --- | --- |
| Info.plist | `NSCameraUsageDescription` configurata tramite build setting. | La fotocamera richiede una motivazione esplicita all'utente. | Completato. |
| Target membership | Bundle Swift Testing `FrigoTests` creato e associato all'host. | Esegue i test del modulo. | Completato. |
| App host | Il tab Cibo monta `CiboRootView()` tramite `FoodView`. | Monta l'entry point del modulo. | Completato. |
| Risorse `.md` o `.sh` | Verificare che `Docs/` e `Tools/` non siano copiati nelle risorse del bundle. | Non sono risorse runtime. | Da verificare manualmente. |
