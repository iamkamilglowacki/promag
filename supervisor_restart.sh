#!/bin/bash

# Restart aplikacji przez Supervisor

echo "🔄 Restart aplikacji..."
echo "======================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'

echo "🔄 Restartowanie aplikacji..."
~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf restart promag

sleep 3

echo ""
echo "📊 Status po restarcie:"
~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status

EOF

echo ""
echo "======================="
echo "✅ Restart zakończony!"
echo ""
echo "Sprawdź: https://promag.flavorinthejar.com/"
