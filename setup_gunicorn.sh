#!/bin/bash

# Konfiguracja Gunicorn dla stabilnej produkcji

echo "🔧 Konfiguracja Gunicorn..."
echo "============================"
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Instalacja Gunicorn
echo "📦 Instalacja Gunicorn..."
pip3 install --user gunicorn

# Utwórz plik konfiguracyjny Gunicorn
cat > ~/promag/gunicorn_config.py << 'CONFIG'
import multiprocessing

# Adres i port
bind = "0.0.0.0:5001"

# Workery
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# Logowanie
accesslog = "/home/u923457281/promag/gunicorn_access.log"
errorlog = "/home/u923457281/promag/gunicorn_error.log"
loglevel = "info"

# Proces
daemon = True
pidfile = "/home/u923457281/promag/gunicorn.pid"
user = "u923457281"

# Restart
max_requests = 1000
max_requests_jitter = 50
CONFIG

echo "✅ Konfiguracja Gunicorn utworzona"

# Zatrzymaj starą aplikację
pkill -f "python.*app.py" 2>/dev/null || true
pkill -f "gunicorn" 2>/dev/null || true
sleep 2

# Uruchom Gunicorn
echo "🚀 Uruchamianie Gunicorn..."
cd ~/promag
~/.local/bin/gunicorn -c gunicorn_config.py app:app

sleep 3

# Sprawdź czy działa
if ps aux | grep -v grep | grep "gunicorn" > /dev/null; then
    echo "✅ Gunicorn uruchomiony!"
    ps aux | grep -v grep | grep "gunicorn" | head -3
else
    echo "❌ Błąd uruchamiania!"
    tail -20 gunicorn_error.log
fi

echo ""
echo "============================"
echo "✅ Gunicorn skonfigurowany!"
echo ""
echo "Komendy:"
echo "  Stop:    kill \$(cat ~/promag/gunicorn.pid)"
echo "  Restart: kill -HUP \$(cat ~/promag/gunicorn.pid)"
echo "  Logi:    tail -f ~/promag/gunicorn_error.log"
EOF
