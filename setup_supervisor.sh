#!/bin/bash

# Instalacja i konfiguracja Supervisor dla stabilnej aplikacji

echo "🔧 Konfiguracja Supervisor..."
echo "=============================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Sprawdź czy supervisor jest zainstalowany
if ! command -v supervisorctl &> /dev/null; then
    echo "📦 Instalacja Supervisor..."
    pip3 install --user supervisor
    
    # Dodaj do PATH
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Utwórz katalog konfiguracyjny
mkdir -p ~/supervisor
mkdir -p ~/supervisor/logs

# Utwórz konfigurację supervisor
cat > ~/supervisor/supervisord.conf << 'CONFIG'
[unix_http_server]
file=%(here)s/supervisor.sock

[supervisord]
logfile=%(here)s/logs/supervisord.log
logfile_maxbytes=50MB
logfile_backups=10
loglevel=info
pidfile=%(here)s/supervisord.pid
nodaemon=false
minfds=1024
minprocs=200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix://%(here)s/supervisor.sock

[program:promag]
command=/usr/bin/python3 /home/u923457281/promag/app.py
directory=/home/u923457281/promag
user=u923457281
autostart=true
autorestart=true
startretries=3
stderr_logfile=%(here)s/logs/promag.err.log
stdout_logfile=%(here)s/logs/promag.out.log
environment=HOME="/home/u923457281",USER="u923457281"
CONFIG

echo "✅ Konfiguracja utworzona"

# Zatrzymaj starą aplikację
pkill -f "python.*app.py" 2>/dev/null || true
sleep 2

# Uruchom supervisor
echo "🚀 Uruchamianie Supervisor..."
~/.local/bin/supervisord -c ~/supervisor/supervisord.conf

sleep 3

# Sprawdź status
echo ""
echo "📊 Status aplikacji:"
~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status

echo ""
echo "=============================="
echo "✅ Supervisor skonfigurowany!"
echo ""
echo "Komendy:"
echo "  Status:   supervisorctl -c ~/supervisor/supervisord.conf status"
echo "  Restart:  supervisorctl -c ~/supervisor/supervisord.conf restart promag"
echo "  Stop:     supervisorctl -c ~/supervisor/supervisord.conf stop promag"
echo "  Start:    supervisorctl -c ~/supervisor/supervisord.conf start promag"
echo "  Logi:     tail -f ~/supervisor/logs/promag.out.log"
EOF
