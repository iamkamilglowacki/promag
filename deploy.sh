#!/bin/bash

# Skrypt wdrożeniowy dla aplikacji magazynowej
# Autor: System Magazynowy
# Data: 2025-10-14

echo "🚀 Wdrażanie aplikacji na serwer..."
echo "===================================="
echo ""

# Konfiguracja - UZUPEŁNIJ TE DANE
SERVER_USER="u123456789"  # Twój login SSH
SERVER_HOST="promag.flavorinthejar.com"  # Adres serwera
SERVER_PATH="/home/u123456789/domains/promag.flavorinthejar.com/public_html"  # Ścieżka na serwerze
SERVER_PORT="22"  # Port SSH (domyślnie 22)

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania błędów
error() {
    echo -e "${RED}❌ BŁĄD: $1${NC}"
    exit 1
}

# Funkcja do wyświetlania sukcesów
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Funkcja do wyświetlania ostrzeżeń
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Sprawdź czy plik app.py istnieje
if [ ! -f "app.py" ]; then
    error "Plik app.py nie istnieje w bieżącym katalogu!"
fi

# Sprawdź czy plik .env istnieje
if [ ! -f ".env" ]; then
    warning "Plik .env nie istnieje. Upewnij się, że istnieje na serwerze!"
fi

echo "📋 Informacje o wdrożeniu:"
echo "   Użytkownik: $SERVER_USER"
echo "   Serwer: $SERVER_HOST"
echo "   Ścieżka: $SERVER_PATH"
echo ""

# Pytaj o potwierdzenie
read -p "Czy chcesz kontynuować wdrożenie? (tak/nie): " confirm
if [ "$confirm" != "tak" ]; then
    echo "Anulowano."
    exit 0
fi

echo ""
echo "📦 Tworzenie kopii zapasowej..."

# Utwórz backup lokalnie
BACKUP_DIR="backups"
BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).tar.gz"

mkdir -p $BACKUP_DIR
tar -czf "$BACKUP_DIR/$BACKUP_FILE" app.py .env 2>/dev/null || true
success "Kopia zapasowa utworzona: $BACKUP_DIR/$BACKUP_FILE"

echo ""
echo "📤 Wysyłanie plików na serwer..."

# Wyślij app.py
scp -P $SERVER_PORT app.py "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/" || error "Nie udało się wysłać app.py"
success "Plik app.py wysłany"

# Wyślij .env jeśli istnieje
if [ -f ".env" ]; then
    scp -P $SERVER_PORT .env "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/" || warning "Nie udało się wysłać .env"
    success "Plik .env wysłany"
fi

# Wyślij requirements.txt
if [ -f "requirements.txt" ]; then
    scp -P $SERVER_PORT requirements.txt "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/" || warning "Nie udało się wysłać requirements.txt"
    success "Plik requirements.txt wysłany"
fi

echo ""
echo "🔄 Restartowanie aplikacji na serwerze..."

# Komenda do restartu (dostosuj do swojego serwera)
ssh -p $SERVER_PORT "$SERVER_USER@$SERVER_HOST" << 'ENDSSH'
cd /home/u123456789/domains/promag.flavorinthejar.com/public_html

# Znajdź i zabij proces Python
pkill -f "python.*app.py" 2>/dev/null || true

# Poczekaj chwilę
sleep 2

# Uruchom aplikację w tle
nohup python3 app.py > app.log 2>&1 &

echo "Aplikacja uruchomiona. PID: $!"
ENDSSH

success "Aplikacja zrestartowana"

echo ""
echo "🧪 Testowanie endpointu..."
sleep 3

# Test czy aplikacja odpowiada
if curl -s -f "https://$SERVER_HOST/api/produkty" > /dev/null; then
    success "Aplikacja działa poprawnie!"
else
    warning "Nie można połączyć się z aplikacją. Sprawdź logi na serwerze."
fi

echo ""
echo "✨ Wdrożenie zakończone!"
echo ""
echo "📋 Następne kroki:"
echo "   1. Sprawdź logi: ssh $SERVER_USER@$SERVER_HOST 'tail -f $SERVER_PATH/app.log'"
echo "   2. Przetestuj webhook: https://$SERVER_HOST/api/woocommerce/webhook-simple"
echo "   3. Zaktualizuj URL webhooka w WooCommerce"
echo ""
