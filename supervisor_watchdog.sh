#!/bin/bash

LOG_FILE="$HOME/promag/supervisor_watchdog.log"
BACKUP_FLAG="$HOME/promag/.backup_done_today"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Sprawdź czy trzeba zrobić backup (raz dziennie o północy)
CURRENT_DATE=$(date +%Y%m%d)
CURRENT_HOUR=$(date +%H)

# Jeśli jest między 00:00 a 01:00 i backup nie został jeszcze wykonany dzisiaj
if [ "$CURRENT_HOUR" = "00" ]; then
    if [ ! -f "$BACKUP_FLAG" ] || [ "$(cat $BACKUP_FLAG 2>/dev/null)" != "$CURRENT_DATE" ]; then
        log "🕐 Północ - wykonuję backup..."
        ~/promag/backup_database.sh
        echo "$CURRENT_DATE" > "$BACKUP_FLAG"
    fi
fi

# Sprawdź czy Supervisor działa
if ! ps aux | grep -v grep | grep "supervisord" > /dev/null; then
    log "❌ Supervisor nie działa! Uruchamiam..."
    
    pkill -9 -f "supervisord" 2>/dev/null || true
    pkill -9 -f "python.*app.py" 2>/dev/null || true
    sleep 2
    
    ~/.local/bin/supervisord -c ~/supervisor/supervisord.conf
    sleep 5
    
    if ps aux | grep -v grep | grep "supervisord" > /dev/null; then
        log "✅ Supervisor uruchomiony ponownie"
    else
        log "❌ BŁĄD: Nie udało się uruchomić Supervisor!"
    fi
else
    # Sprawdź czy aplikacja działa
    STATUS=$(~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status promag 2>/dev/null | awk '{print $2}')
    
    if [ "$STATUS" != "RUNNING" ]; then
        log "⚠️  Aplikacja nie działa (status: $STATUS)! Restartuję..."
        ~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf restart promag
        log "✅ Aplikacja zrestartowana"
    fi
    
    # Sprawdź czy aplikacja odpowiada
    if ! curl -s -f http://localhost:5001/ > /dev/null 2>&1; then
        log "⚠️  Aplikacja nie odpowiada! Restartuję..."
        ~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf restart promag
        log "✅ Aplikacja zrestartowana"
    fi
fi
