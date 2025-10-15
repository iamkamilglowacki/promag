#!/bin/bash

# Sprawdź status Supervisor i aplikacji

echo "📊 Status Supervisor"
echo "===================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Status aplikacji
echo "🔹 Status aplikacji:"
~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status

echo ""
echo "🔹 Procesy:"
ps aux | grep -E "supervisor|python.*app.py" | grep -v grep | head -5

echo ""
echo "🔹 Ostatnie logi (10 linii):"
tail -10 ~/supervisor/logs/promag.out.log

echo ""
echo "🔹 Błędy (jeśli są):"
if [ -s ~/supervisor/logs/promag.err.log ]; then
    tail -10 ~/supervisor/logs/promag.err.log
else
    echo "Brak błędów"
fi

EOF

echo ""
echo "===================="
echo "🌐 Test aplikacji:"
curl -s -o /dev/null -w "Status: %{http_code}\n" https://promag.flavorinthejar.com/
