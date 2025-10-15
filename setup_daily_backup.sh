#!/bin/bash

# Konfiguracja codziennego backupu o północy

echo "⏰ Konfiguracja automatycznego backupu..."
echo "=========================================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Utwórz skrypt backupu na serwerze
cat > ~/promag/backup_database.sh << 'BACKUP'
#!/bin/bash

# Automatyczny backup bazy danych

BACKUP_DIR="$HOME/promag/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="magazyn_backup_$DATE.db"
LOG_FILE="$HOME/promag/backup.log"

# Funkcja logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Utwórz katalog jeśli nie istnieje
mkdir -p "$BACKUP_DIR"

# Skopiuj bazę danych
if cp "$HOME/promag/magazyn.db" "$BACKUP_DIR/$BACKUP_FILE"; then
    log "✅ Backup utworzony: $BACKUP_FILE"
    
    # Usuń backupy starsze niż 30 dni
    DELETED=$(find "$BACKUP_DIR" -name "magazyn_backup_*.db" -mtime +30 -delete -print | wc -l)
    if [ "$DELETED" -gt 0 ]; then
        log "🗑️  Usunięto $DELETED starych backupów"
    fi
    
    # Pokaż liczbę backupów
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/magazyn_backup_*.db 2>/dev/null | wc -l)
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log "📊 Liczba backupów: $BACKUP_COUNT | Rozmiar: $BACKUP_SIZE"
else
    log "❌ Błąd podczas tworzenia backupu!"
    exit 1
fi
BACKUP

chmod +x ~/promag/backup_database.sh

# Utwórz skrypt do uruchamiania backupu w pętli
cat > ~/promag/start_backup_scheduler.sh << 'SCHEDULER'
#!/bin/bash

# Zatrzymaj stary scheduler
pkill -f "backup_scheduler" 2>/dev/null || true

# Uruchom scheduler w tle
(
while true; do
    # Oblicz czas do północy
    CURRENT_TIME=$(date +%s)
    MIDNIGHT=$(date -d "tomorrow 00:00:00" +%s 2>/dev/null || date -v +1d -v 0H -v 0M -v 0S +%s)
    SLEEP_TIME=$((MIDNIGHT - CURRENT_TIME))
    
    # Jeśli czas ujemny (błąd), czekaj 1 godzinę
    if [ $SLEEP_TIME -lt 0 ]; then
        SLEEP_TIME=3600
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Następny backup za $((SLEEP_TIME / 3600))h $((SLEEP_TIME % 3600 / 60))m" >> ~/promag/backup.log
    
    # Czekaj do północy
    sleep $SLEEP_TIME
    
    # Wykonaj backup
    ~/promag/backup_database.sh
    
    # Czekaj 60 sekund aby uniknąć podwójnego wykonania
    sleep 60
done
) &

echo "Backup Scheduler uruchomiony! PID: $!"
echo $! > ~/promag/backup_scheduler.pid
SCHEDULER

chmod +x ~/promag/start_backup_scheduler.sh

# Uruchom scheduler
echo "🚀 Uruchamianie Backup Scheduler..."
~/promag/start_backup_scheduler.sh

# Wykonaj pierwszy backup od razu
echo "📦 Tworzenie pierwszego backupu..."
~/promag/backup_database.sh

EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Automatyczny backup skonfigurowany!"
    echo ""
    echo "📋 Szczegóły:"
    echo "  • Backup: Codziennie o 00:00"
    echo "  • Lokalizacja: ~/promag/backups/"
    echo "  • Retencja: 30 dni"
    echo "  • Logi: ~/promag/backup.log"
    echo ""
    echo "🔍 Sprawdź backupy:"
    echo "  ssh -p 65002 u923457281@46.17.175.219 'ls -lh ~/promag/backups/'"
    echo ""
    echo "📋 Sprawdź logi:"
    echo "  ssh -p 65002 u923457281@46.17.175.219 'tail -20 ~/promag/backup.log'"
    echo ""
    echo "🛑 Zatrzymaj scheduler:"
    echo "  ssh -p 65002 u923457281@46.17.175.219 'kill \$(cat ~/promag/backup_scheduler.pid)'"
else
    echo ""
    echo "=========================================="
    echo "❌ Wystąpił błąd podczas konfiguracji!"
fi
