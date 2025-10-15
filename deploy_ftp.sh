#!/bin/bash

# Prosty skrypt wdrożeniowy przez FTP
# Dla serwerów Hostinger

echo "🚀 Wdrażanie przez FTP..."
echo "========================"
echo ""

# KONFIGURACJA - UZUPEŁNIJ!
FTP_HOST="ftp.flavorinthejar.com"
FTP_USER="u123456789"  # Twój login FTP
FTP_PASS=""  # Zostaw puste - zostaniesz poproszony o hasło
FTP_PATH="/domains/promag.flavorinthejar.com/public_html"

echo "⚠️  UWAGA: Ten skrypt wymaga zainstalowanego 'lftp'"
echo ""
echo "Jeśli nie masz lftp, zainstaluj:"
echo "  brew install lftp"
echo ""

# Sprawdź czy lftp jest zainstalowane
if ! command -v lftp &> /dev/null; then
    echo "❌ lftp nie jest zainstalowane!"
    echo "Zainstaluj: brew install lftp"
    exit 1
fi

# Sprawdź czy plik app.py istnieje
if [ ! -f "app.py" ]; then
    echo "❌ Plik app.py nie istnieje!"
    exit 1
fi

echo "📤 Wysyłanie plików przez FTP..."
echo "Host: $FTP_HOST"
echo "Użytkownik: $FTP_USER"
echo ""

# Wyślij pliki przez FTP
lftp -u "$FTP_USER" "$FTP_HOST" << EOF
cd $FTP_PATH
put app.py
put .env
put requirements.txt
bye
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Pliki wysłane pomyślnie!"
    echo ""
    echo "⚠️  WAŻNE: Musisz teraz zrestartować aplikację na serwerze!"
    echo ""
    echo "Opcje restartu:"
    echo "1. Panel Hostinger → Python App → Restart"
    echo "2. SSH: pkill -f 'python.*app.py' && nohup python3 app.py &"
    echo ""
else
    echo ""
    echo "❌ Błąd podczas wysyłania plików!"
fi
