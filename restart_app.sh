#!/bin/bash

# Prosty skrypt do restartowania aplikacji na serwerze

echo "🔄 Restartowanie aplikacji na serwerze..."
echo "=========================================="

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'
cd ~/promag

echo "🛑 Zatrzymywanie starej aplikacji..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 2

echo "🚀 Uruchamianie aplikacji..."
nohup python3 app.py > app.log 2>&1 &

sleep 3

if ps aux | grep -v grep | grep "python.*app.py" > /dev/null; then
    echo "✅ Aplikacja uruchomiona!"
    ps aux | grep -v grep | grep "python.*app.py" | head -1
else
    echo "❌ Błąd uruchamiania!"
    tail -20 app.log
    exit 1
fi
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Aplikacja działa!"
    echo ""
    echo "Sprawdź: https://promag.flavorinthejar.com/"
else
    echo ""
    echo "=========================================="
    echo "❌ Wystąpił błąd!"
fi
