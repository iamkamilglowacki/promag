#!/bin/bash

# Szybkie wdrożenie - tylko app.py

echo "🚀 Szybkie wdrożenie app.py..."
echo ""

# Dane serwera
SERVER_USER="u923457281"
SERVER_IP="46.17.175.219"
SERVER_PORT="65002"
SERVER_PATH="/home/u923457281/domains/promag.flavorinthejar.com/public_html"

echo "📤 Wysyłanie app.py..."
scp -P $SERVER_PORT app.py $SERVER_USER@$SERVER_IP:$SERVER_PATH/

if [ $? -eq 0 ]; then
    echo "✅ Plik wysłany!"
    echo ""
    echo "🔄 Restartowanie aplikacji..."
    
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << 'ENDSSH'
# Przejdź do katalogu
cd /home/u923457281/domains/promag.flavorinthejar.com/public_html

# Zabij stary proces
pkill -f "python.*app.py" 2>/dev/null || true

# Poczekaj
sleep 2

# Uruchom nową wersję
nohup python3 app.py > app.log 2>&1 &

echo "✅ Aplikacja uruchomiona!"
echo "PID: $!"
ENDSSH

    echo ""
    echo "🧪 Testowanie..."
    sleep 3
    
    curl -s https://promag.flavorinthejar.com/api/woocommerce/webhook \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"status":"completed","id":999,"line_items":[]}'
    
    echo ""
    echo ""
    echo "✅ GOTOWE!"
    echo ""
    echo "Przetestuj webhook w WooCommerce:"
    echo "https://promag.flavorinthejar.com/api/woocommerce/webhook"
    
else
    echo "❌ Błąd podczas wysyłania pliku!"
fi
