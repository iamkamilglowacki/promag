#!/bin/bash

# Uniwersalny skrypt do uruchamiania całego systemu

echo "🚀 Uruchamianie systemu magazynowego..."
echo "========================================"
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

# Zabij stare procesy
echo "🧹 Czyszczenie starych procesów..."
pkill -9 -f "supervisord" 2>/dev/null || true
pkill -9 -f "python.*app.py" 2>/dev/null || true
sleep 2

# Uruchom Supervisor
echo "🚀 Uruchamianie Supervisor..."
~/.local/bin/supervisord -c ~/supervisor/supervisord.conf

sleep 5

# Sprawdź status
STATUS=$(~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status promag | awk '{print $2}')

if [ "$STATUS" = "RUNNING" ]; then
    echo "✅ Supervisor uruchomiony!"
    echo "✅ Aplikacja działa!"
    ~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status
else
    echo "❌ Problem z uruchomieniem!"
    echo "Status: $STATUS"
    tail -20 ~/supervisor/logs/promag.err.log
    exit 1
fi

EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ System uruchomiony pomyślnie!"
    echo ""
    echo "Sprawdź:"
    echo "  • https://promag.flavorinthejar.com/"
    echo "  • ./supervisor_status.sh"
    echo ""
    
    # Test końcowy
    sleep 3
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://promag.flavorinthejar.com/)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "🌐 Aplikacja dostępna publicznie: ✅"
    else
        echo "⚠️  Aplikacja zwraca kod: $HTTP_CODE"
    fi
else
    echo ""
    echo "========================================"
    echo "❌ Wystąpił błąd podczas uruchamiania!"
fi
