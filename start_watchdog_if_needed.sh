#!/bin/bash

# Skrypt uruchamiany przez Cron - sprawdza czy watchdog działa
# Jeśli nie - uruchamia go

LOG_FILE="$HOME/promag/watchdog_cron.log"

# Funkcja logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Sprawdź czy watchdog już działa
if ps aux | grep "while true.*supervisor_watchdog" | grep -v grep > /dev/null; then
    # Watchdog działa - nic nie rób
    exit 0
fi

# Watchdog nie działa - sprawdź czy Supervisor działa
if ! ps aux | grep "supervisord" | grep -v grep > /dev/null; then
    log "⚠️  Supervisor nie działa! Uruchamiam cały system..."
    
    # Wyczyść stare procesy
    pkill -9 -f "supervisord" 2>/dev/null || true
    pkill -9 -f "python.*app.py" 2>/dev/null || true
    sleep 2
    
    # Uruchom Supervisor
    ~/.local/bin/supervisord -c ~/supervisor/supervisord.conf
    sleep 5
    
    log "✅ Supervisor uruchomiony"
fi

# Uruchom watchdog
nohup bash -c 'while true; do ~/promag/supervisor_watchdog.sh; sleep 60; done' > /dev/null 2>&1 &
WATCHDOG_PID=$!

log "✅ Watchdog uruchomiony (PID: $WATCHDOG_PID)"
