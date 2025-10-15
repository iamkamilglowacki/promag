#!/bin/bash

# Integracja backupu z watchdogiem

echo "🔄 Konfiguracja backupu z watchdogiem..."
echo "=========================================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Utwórz skrypt backupu
cat > ~/promag/backup_database.sh << 'BACKUP'
#!/bin/bash

BACKUP_DIR="$HOME/promag/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="magazyn_backup_$DATE.db"
LOG_FILE="$HOME/promag/backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

if cp "$HOME/promag/magazyn.db" "$BACKUP_DIR/$BACKUP_FILE"; then
    log "✅ Backup utworzony: $BACKUP_FILE"
    
    # Usuń backupy starsze niż 30 dni
    find "$BACKUP_DIR" -name "magazyn_backup_*.db" -mtime +30 -delete
    
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/magazyn_backup_*.db 2>/dev/null | wc -l)
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log "📊 Backupów: $BACKUP_COUNT | Rozmiar: $BACKUP_SIZE"
else
    log "❌ Błąd backupu!"
    exit 1
fi
BACKUP

chmod +x ~/promag/backup_database.sh

# Zmodyfikuj watchdog aby robił backup o północy
cat > ~/promag/supervisor_watchdog.sh << 'WATCHDOG'
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
WATCHDOG

chmod +x ~/promag/supervisor_watchdog.sh

# Wykonaj pierwszy backup
echo "📦 Tworzenie pierwszego backupu..."
~/promag/backup_database.sh

EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Backup zintegrowany z watchdogiem!"
    echo ""
    echo "📋 Jak to działa:"
    echo "  • Watchdog sprawdza co 60 sekund"
    echo "  • Między 00:00-01:00 wykonuje backup"
    echo "  • Backup tylko raz dziennie"
    echo "  • Stare backupy (>30 dni) są usuwane"
    echo ""
    echo "📁 Lokalizacja: ~/promag/backups/"
    echo "📋 Logi: ~/promag/backup.log"
    echo ""
    echo "🔍 Sprawdź backupy:"
    echo "  ssh -p 65002 u923457281@46.17.175.219 'ls -lh ~/promag/backups/'"
    echo ""
    echo "⚠️  WAŻNE: Watchdog musi działać!"
    echo "  Sprawdź: ps aux | grep supervisor_watchdog"
else
    echo ""
    echo "=========================================="
    echo "❌ Wystąpił błąd!"
fi
