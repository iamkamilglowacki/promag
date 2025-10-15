#!/bin/bash

# Prosty watchdog - sprawdza czy aplikacja działa i restartuje jeśli nie

echo "🐕 Konfiguracja Watchdog..."
echo "============================"
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Utwórz skrypt watchdog
cat > ~/promag/watchdog.sh << 'WATCHDOG'
#!/bin/bash

LOG_FILE="$HOME/promag/watchdog.log"
APP_DIR="$HOME/promag"

# Funkcja logowania
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Sprawdź czy aplikacja działa
if ! ps aux | grep -v grep | grep "python.*app.py" > /dev/null; then
    log "❌ Aplikacja nie działa! Restartuję..."
    
    cd "$APP_DIR"
    pkill -f "python.*app.py" 2>/dev/null || true
    sleep 2
    
    nohup python3 app.py > app.log 2>&1 &
    
    sleep 3
    
    if ps aux | grep -v grep | grep "python.*app.py" > /dev/null; then
        log "✅ Aplikacja uruchomiona ponownie"
    else
        log "❌ BŁĄD: Nie udało się uruchomić aplikacji!"
    fi
else
    # Sprawdź czy aplikacja odpowiada
    if ! curl -s -f http://localhost:5001/ > /dev/null 2>&1; then
        log "⚠️  Aplikacja nie odpowiada! Restartuję..."
        
        cd "$APP_DIR"
        pkill -f "python.*app.py" 2>/dev/null || true
        sleep 2
        
        nohup python3 app.py > app.log 2>&1 &
        
        sleep 3
        log "✅ Aplikacja zrestartowana"
    fi
fi
WATCHDOG

chmod +x ~/promag/watchdog.sh

echo "✅ Watchdog utworzony"

# Utwórz skrypt do uruchamiania watchdog w tle
cat > ~/promag/start_watchdog.sh << 'START'
#!/bin/bash

# Zatrzymaj stary watchdog
pkill -f "watchdog.sh" 2>/dev/null || true

# Uruchom watchdog w tle (sprawdza co 60 sekund)
while true; do
    ~/promag/watchdog.sh
    sleep 60
done &

echo "Watchdog uruchomiony! PID: $!"
echo $! > ~/promag/watchdog.pid
START

chmod +x ~/promag/start_watchdog.sh

# Uruchom watchdog
echo "🚀 Uruchamianie Watchdog..."
~/promag/start_watchdog.sh

echo ""
echo "============================"
echo "✅ Watchdog skonfigurowany!"
echo ""
echo "Watchdog sprawdza aplikację co 60 sekund i restartuje jeśli nie działa."
echo ""
echo "Komendy:"
echo "  Logi:    tail -f ~/promag/watchdog.log"
echo "  Stop:    kill \$(cat ~/promag/watchdog.pid)"
echo "  Restart: ~/promag/start_watchdog.sh"
EOF
