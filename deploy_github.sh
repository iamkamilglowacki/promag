#!/bin/bash

# Wdrożenie przez GitHub - NAJPROSTSZE!

echo "🚀 Wdrożenie przez GitHub"
echo "========================="
echo ""

# Dane serwera
SERVER_USER="u923457281"
SERVER_IP="46.17.175.219"
SERVER_PORT="65002"
SERVER_PATH="/home/u923457281/domains/promag.flavorinthejar.com/public_html"

echo "📋 INSTRUKCJA:"
echo ""
echo "1. Utwórz repozytorium na GitHub:"
echo "   - Przejdź do: https://github.com/new"
echo "   - Nazwa: MagazynProdukcja"
echo "   - Prywatne: TAK (zalecane)"
echo "   - Kliknij 'Create repository'"
echo ""
echo "2. Skopiuj URL repozytorium (np. https://github.com/twojnick/MagazynProdukcja.git)"
echo ""
read -p "Wklej URL repozytorium GitHub: " GITHUB_URL

if [ -z "$GITHUB_URL" ]; then
    echo "❌ Nie podano URL!"
    exit 1
fi

echo ""
echo "📤 Wysyłanie kodu do GitHub..."

# Dodaj remote
git remote add origin "$GITHUB_URL" 2>/dev/null || git remote set-url origin "$GITHUB_URL"

# Push do GitHub
git push -u origin main

if [ $? -ne 0 ]; then
    echo "❌ Błąd podczas wysyłania do GitHub!"
    echo ""
    echo "Jeśli to pierwsze wysyłanie, możesz potrzebować:"
    echo "  git config --global user.name 'Twoje Imię'"
    echo "  git config --global user.email 'twoj@email.com'"
    exit 1
fi

echo "✅ Kod wysłany do GitHub!"
echo ""
echo "🔄 Teraz wdrażam na serwer..."
echo ""
echo "To będzie wymagało hasła SSH (tylko raz!)"
echo ""

# Wdróż na serwer
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << ENDSSH
cd $SERVER_PATH

# Jeśli to pierwsze wdrożenie - sklonuj repo
if [ ! -d ".git" ]; then
    echo "📥 Klonowanie repozytorium..."
    cd ..
    rm -rf public_html_backup
    mv public_html public_html_backup
    git clone $GITHUB_URL public_html
    cd public_html
    
    # Skopiuj .env z backupu
    if [ -f ../public_html_backup/.env ]; then
        cp ../public_html_backup/.env .
        echo "✅ Skopiowano .env"
    fi
else
    echo "🔄 Aktualizacja z GitHub..."
    git pull origin main
fi

# Restart aplikacji
echo "🔄 Restartowanie aplikacji..."
pkill -f "python.*app.py" 2>/dev/null || true
sleep 2
nohup python3 app.py > app.log 2>&1 &
echo "✅ Aplikacja uruchomiona! PID: \$!"
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ WDROŻENIE ZAKOŃCZONE!"
    echo ""
    echo "🧪 Testowanie..."
    sleep 3
    
    curl -s https://promag.flavorinthejar.com/api/woocommerce/webhook \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"status":"completed","id":999,"line_items":[]}' | jq . || echo ""
    
    echo ""
    echo "🎉 GOTOWE!"
    echo ""
    echo "📋 Następne wdrożenia:"
    echo "  1. Zmień kod lokalnie"
    echo "  2. git add ."
    echo "  3. git commit -m 'opis zmian'"
    echo "  4. ./deploy_github.sh"
    echo ""
else
    echo "❌ Błąd podczas wdrażania!"
fi
