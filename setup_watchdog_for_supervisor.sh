#!/bin/bash

# Watchdog który pilnuje Supervisor

echo "🐕 Konfiguracja Watchdog dla Supervisor..."
echo "==========================================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Utwórz watchdog dla Supervisor
cat > ~/promag/supervisor_watchdog.sh << 'WATCHDOG'
#!/bin/bash

LOG_FILE="$HOME/promag/supervisor_watchdog.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Sprawdź czy Supervisor działa
if ! ps aux | grep -v grep | grep "supervisord" > /dev/null; then
    log "❌ Supervisor nie działa! Uruchamiam..."
    
    # Zabij stare procesy
    pkill -9 -f "supervisord" 2>/dev/null || true
    pkill -9 -f "python.*app.py" 2>/dev/null || true
    sleep 2
    
    # Uruchom Supervisor
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
        log "⚠️  Aplikacja nie odpowiada! Restartuję przez Supervisor..."
        ~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf restart promag
        log "✅ Aplikacja zrestartowana"
    fi
fi
WATCHDOG

chmod +x ~/promag/supervisor_watchdog.sh

# Utwórz skrypt do uruchamiania watchdog
cat > ~/promag/start_supervisor_watchdog.sh << 'START'
#!/bin/bash

# Zatrzymaj stary watchdog
pkill -f "supervisor_watchdog" 2>/dev/null || true

# Uruchom watchdog w tle (sprawdza co 60 sekund)
(
while true; do
    ~/promag/supervisor_watchdog.sh
    sleep 60
done
) &

echo "Supervisor Watchdog uruchomiony! PID: $!"
echo $! > ~/promag/supervisor_watchdog.pid
START

chmod +x ~/promag/start_supervisor_watchdog.sh

# Uruchom watchdog
echo "🚀 Uruchamianie Watchdog..."
~/promag/start_supervisor_watchdog.sh

echo ""
echo "==========================================="
echo "✅ Watchdog skonfigurowany!"
echo ""
echo "Watchdog sprawdza co 60 sekund:"
echo "  1. Czy Supervisor działa → jeśli nie, uruchamia"
echo "  2. Czy aplikacja działa → jeśli nie, restartuje"
echo "  3. Czy aplikacja odpowiada → jeśli nie, restartuje"
echo ""
echo "Logi: ~/promag/supervisor_watchdog.log"
echo "Stop: kill \$(cat ~/promag/supervisor_watchdog.pid)"
EOF
