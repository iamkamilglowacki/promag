#!/bin/bash

# Skrypt uruchamiający System Magazynowy

echo "🏭 System Magazynowy - Mieszanki Przypraw"
echo "========================================"

# Sprawdź czy istnieje środowisko wirtualne
if [ ! -d "venv" ]; then
    echo "📦 Tworzenie środowiska wirtualnego..."
    python3 -m venv venv
fi

# Aktywuj środowisko wirtualne
echo "🔧 Aktywacja środowiska wirtualnego..."
source venv/bin/activate

# Zainstaluj zależności jeśli nie są zainstalowane
echo "📋 Sprawdzanie zależności..."
pip install -r requirements.txt > /dev/null 2>&1

# Znajdź adres IP
echo "🌐 Znajdowanie adresu IP..."
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

echo ""
echo "✅ Aplikacja będzie dostępna pod adresami:"
echo "   Lokalnie:        http://localhost:5001"
echo "   W sieci lokalnej: http://$IP:5001"
echo ""
echo "📱 Aby uzyskać dostęp z tableta/telefonu:"
echo "   1. Upewnij się, że urządzenia są w tej samej sieci Wi-Fi"
echo "   2. Otwórz przeglądarkę na urządzeniu mobilnym"
echo "   3. Wpisz adres: http://$IP:5001"
echo ""
echo "🚀 Uruchamianie aplikacji..."
echo "   (Naciśnij Ctrl+C aby zatrzymać)"
echo ""

# Uruchom aplikację
python app.py
