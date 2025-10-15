#!/bin/bash

echo "📋 Logi webhooków z serwera:"
echo "============================"
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'
cd ~/promag

echo "Ostatnie 50 linii z webhook_debug.log:"
echo "--------------------------------------"
tail -50 webhook_debug.log 2>/dev/null || echo "Brak pliku webhook_debug.log - czekam na pierwsze requesty"

echo ""
echo "Ostatnie błędy z app.log:"
echo "-------------------------"
tail -30 app.log | grep -E "ERROR|400|500|Exception" || echo "Brak błędów"
EOF
