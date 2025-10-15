#!/bin/bash

# Sprawdź logi webhooka na serwerze

echo "📋 Ostatnie requesty do webhooka:"
echo "=================================="

ssh -p 65002 u923457281@46.17.175.219 << 'ENDSSH'
cd ~/promag

# Pokaż ostatnie 100 linii logu
echo ""
echo "Ostatnie logi aplikacji:"
tail -100 app.log | tail -50

echo ""
echo "=================================="
echo "Szukam błędów 400:"
tail -200 app.log | grep -B 10 "400"

ENDSSH
