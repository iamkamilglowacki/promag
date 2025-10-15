#!/bin/bash

# Skrypt do konfiguracji automatycznego uruchamiania aplikacji

echo "🔧 Konfiguracja automatycznego uruchamiania..."
echo "=============================================="
echo ""

# Utwórz skrypt startowy
cat > ~/promag/start_app.sh << 'SCRIPT'
#!/bin/bash
cd ~/promag
pkill -f "python.*app.py" 2>/dev/null || true
sleep 2
nohup python3 app.py > app.log 2>&1 &
echo "Aplikacja uruchomiona: $(date)" >> ~/promag/startup.log
SCRIPT

chmod +x ~/promag/start_app.sh

echo "✅ Skrypt startowy utworzony: ~/promag/start_app.sh"
echo ""

# Dodaj do crontab (uruchom przy restarcie)
echo "📋 Dodawanie do crontab..."
(crontab -l 2>/dev/null | grep -v "start_app.sh"; echo "@reboot ~/promag/start_app.sh") | crontab -

echo "✅ Dodano do crontab"
echo ""

# Utwórz skrypt do sprawdzania czy aplikacja działa
cat > ~/promag/check_app.sh << 'SCRIPT'
#!/bin/bash
if ! ps aux | grep -v grep | grep "python.*app.py" > /dev/null; then
    echo "❌ Aplikacja nie działa! Uruchamiam... $(date)" >> ~/promag/check.log
    ~/promag/start_app.sh
fi
SCRIPT

chmod +x ~/promag/check_app.sh

echo "✅ Skrypt sprawdzający utworzony: ~/promag/check_app.sh"
echo ""

# Dodaj sprawdzanie co 5 minut
echo "📋 Dodawanie automatycznego sprawdzania (co 5 minut)..."
(crontab -l 2>/dev/null | grep -v "check_app.sh"; echo "*/5 * * * * ~/promag/check_app.sh") | crontab -

echo "✅ Dodano sprawdzanie co 5 minut"
echo ""

echo "=============================================="
echo "✅ Konfiguracja zakończona!"
echo ""
echo "Aplikacja będzie:"
echo "  • Automatycznie uruchamiana po restarcie serwera"
echo "  • Sprawdzana co 5 minut i restartowana jeśli nie działa"
echo ""
echo "Logi:"
echo "  • Uruchomienia: ~/promag/startup.log"
echo "  • Sprawdzenia: ~/promag/check.log"
echo "  • Aplikacja: ~/promag/app.log"
