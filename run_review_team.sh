#!/bin/bash

# Nome della sessione tmux
SESSION_NAME="frigo-review-team"

# Chiude la sessione precedente se esiste
tmux kill-session -t $SESSION_NAME 2>/dev/null

echo "🧊 Avvio il Team di Revisione Frigo in tmux..."

# Crea una nuova sessione tmux in background
tmux new-session -d -s $SESSION_NAME

# Dividi lo schermo in 4 riquadri (2x2)
tmux split-window -h -p 50  # Divide a metà in orizzontale
tmux select-pane -t 0       # Seleziona il riquadro sinistro
tmux split-window -v -p 50  # Divide il sinistro a metà in verticale
tmux select-pane -t 2       # Seleziona il riquadro destro
tmux split-window -v -p 50  # Divide il destro a metà in verticale

# === Agente 1: L'Architetto (In alto a sinistra) ===
# Analizzerà la logica di business e i modelli
tmux send-keys -t 0 "clear && echo -e '\033[1;34m=== AGENTE 1: L\'ARCHITETTO ===\033[0m' && claude -p 'Fai una review focalizzata unicamente sull\'architettura. Analizza i file in Frigo/Allenamento/Models/ e WorkoutManager.swift. Cerca problemi di stato, accoppiamenti forti o logica inefficiente. Presenta un report a schermo alla fine.' ; read -p 'Premi Invio per chiudere...'" C-m

# === Agente 2: Il Designer SwiftUI (In basso a sinistra) ===
# Analizzerà la UI e le performance di rendering
tmux send-keys -t 1 "clear && echo -e '\033[1;35m=== AGENTE 2: IL DESIGNER UI ===\033[0m' && claude -p 'Fai una review focalizzata sulle View SwiftUI. Analizza Frigo/Allenamento/Views/ e GymView.swift. Cerca problemi di performance nel rendering, modificatori deprecati o UI bloccante. Presenta un report a schermo.' ; read -p 'Premi Invio per chiudere...'" C-m

# === Agente 3: L'Ingegnere di Sistema (In alto a destra) ===
# Analizzerà Widget, Live Activities e Timer
tmux send-keys -t 2 "clear && echo -e '\033[1;32m=== AGENTE 3: INGEGNERE DI SISTEMA ===\033[0m' && claude -p 'Fai una review dei sistemi iOS avanzati del progetto. Analizza FrigoWidgetExtension e WorkoutTimerAttributes.swift. Cerca edge cases nelle Live Activities, potenziali crash o problemi di aggiornamento in background. Presenta un report.' ; read -p 'Premi Invio per chiudere...'" C-m

# === Agente 4: Il Nutrizionista (In basso a destra) ===
# Analizzerà il nuovo modulo Cibo e le sue dipendenze
tmux send-keys -t 3 "clear && echo -e '\033[1;33m=== AGENTE 4: REVISORE MODULO CIBO ===\033[0m' && claude -p 'Fai una review del modulo alimentare. Analizza i file nella cartella Frigo/Cibo/ (ad es. FoodView.swift e relative sottocartelle). Valuta la struttura dati, la scalabilità del codice e l\'integrazione con la UI. Presenta un report.' ; read -p 'Premi Invio per chiudere...'" C-m

# Collega il terminale corrente alla sessione tmux appena creata
tmux attach-session -t $SESSION_NAME
