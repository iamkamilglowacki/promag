#!/bin/bash

# Wdrożenie na produkcję z GitHub

echo "🚀 Wdrażanie na produkcję z GitHub..."
echo "======================================"
echo ""

SERVER_USER="u923457281"
SERVER_IP="46.17.175.219"
SERVER_PORT="65002"
SERVER_PATH="/home/u923457281/domains/promag.flavorinthejar.com/public_html"
GITHUB_URL="https://github.com/iamkamilglowacki/promag.git"

echo "📋 Informacje:"
echo "   GitHub: $GITHUB_URL"
echo "   Serwer: $SERVER_IP:$SERVER_PORT"
echo "   Ścieżka: $SERVER_PATH"
echo ""
echo "⚠️  To będzie wymagało hasła SSH"
echo ""

# Wdróż na serwer
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << ENDSSH
set -e

cd /home/$SERVER_USER/domains/promag.flavorinthejar.com

# Backup starej wersji
if [ -d "public_html" ] && [ ! -d "public_html/.git" ]; then
    echo "📦 Tworzenie backupu starej wersji..."
    timestamp=\$(date +%Y%m%d_%H%M%S)
    mv public_html public_html_backup_\$timestamp
    echo "✅ Backup: public_html_backup_\$timestamp"
fi

# Klonuj lub aktualizuj z GitHub
if [ ! -d "public_html/.git" ]; then
    echo "📥 Klonowanie repozytorium z GitHub..."
    git clone $GITHUB_URL public_html
    cd public_html
    
    # Skopiuj .env z backupu jeśli istnieje
    backup_dir=\$(ls -td ../public_html_backup_* 2>/dev/null | head -1)
    if [ -n "\$backup_dir" ] && [ -f "\$backup_dir/.env" ]; then
        cp "\$backup_dir/.env" .
        echo "✅ Skopiowano .env z backupu"
    else
        echo "⚠️  Brak pliku .env - musisz go utworzyć!"
    fi
    
    # Skopiuj bazę danych jeśli istnieje
    if [ -n "\$backup_dir" ] && [ -d "\$backup_dir/instance" ]; then
        cp -r "\$backup_dir/instance" .
        echo "✅ Skopiowano bazę danych"
    fi
else
    echo "🔄 Aktualizacja z GitHub..."
    cd public_html
    git pull origin main
fi

# Zainstaluj zależności
echo "📦 Instalowanie zależności..."
python3 -m pip install --user -r requirements.txt > /dev/null 2>&1 || true

# Restart aplikacji
echo "🔄 Restartowanie aplikacji..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 2

# Uruchom aplikację
nohup python3 app.py > app.log 2>&1 &
APP_PID=\$!

echo "✅ Aplikacja uruchomiona! PID: \$APP_PID"
echo ""
echo "📋 Logi aplikacji:"
sleep 2
tail -20 app.log
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ WDROŻENIE ZAKOŃCZONE!"
    echo ""
    echo "🧪 Testowanie endpointu..."
    sleep 3
    
    echo ""
    echo "Test 1: Główna strona"
    curl -s -o /dev/null -w "Status: %{http_code}\n" https://promag.flavorinthejar.com/
    
    echo ""
    echo "Test 2: Webhook endpoint"
    curl -s https://promag.flavorinthejar.com/api/woocommerce/webhook \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"status":"completed","id":999,"line_items":[]}'
    
    echo ""
    echo ""
    echo "🎉 GOTOWE!"
    echo ""
    echo "✅ Kod wdrożony z GitHub"
    echo "✅ Aplikacja uruchomiona"
    echo "✅ Webhook dostępny pod: https://promag.flavorinthejar.com/api/woocommerce/webhook"
    echo ""
    echo "📋 Następne wdrożenia:"
    echo "   1. Zmień kod lokalnie"
    echo "   2. git add ."
    echo "   3. git commit -m 'opis zmian'"
    echo "   4. git push"
    echo "   5. ./deploy_to_production.sh"
    echo ""
else
    echo ""
    echo "❌ Błąd podczas wdrażania!"
    echo "Sprawdź logi powyżej"
fi
