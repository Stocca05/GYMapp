#!/bin/zsh

SESSION="claude-frigo"
PROJECT="/Users/stocca/Documents/Programmazione/Frigo"

# Se la sessione esiste già, ci si attacca e basta
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Collegamento alla sessione tmux esistente..."
    tmux attach-session -t "$SESSION"
    exit 0
fi

# Crea una nuova sessione tmux staccata e avvia Claude Code
tmux new-session -d -s "$SESSION" -c "$PROJECT" "claude --dangerously-skip-permissions"

# Configura il mouse nel caso ti serva scrollare dentro Claude
tmux set-option -t "$SESSION" mouse on

# Si attacca alla sessione appena creata
tmux attach-session -t "$SESSION"
