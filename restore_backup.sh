#!/bin/bash

# Przywracanie backupu bazy danych

echo "🔄 Przywracanie backupu..."
echo "=========================="
echo ""

# Pokaż dostępne backupy
echo "📋 Dostępne backupy:"
ssh -p 65002 u923457281@46.17.175.219 "ls -lh ~/promag/backups/" | nl

echo ""
read -p "Podaj nazwę pliku backupu (np. magazyn_backup_20251015_132049.db): " BACKUP_FILE

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Nie podano nazwy pliku!"
    exit 1
fi

echo ""
echo "⚠️  UWAGA: To nadpisze aktualną bazę danych!"
read -p "Czy na pewno chcesz kontynuować? (tak/nie): " CONFIRM

if [ "$CONFIRM" != "tak" ]; then
    echo "❌ Anulowano!"
    exit 0
fi

echo ""
echo "🔄 Przywracanie backupu..."

ssh -p 65002 u923457281@46.17.175.219 "bash -s" << EOF
# Sprawdź czy backup istnieje
if [ ! -f ~/promag/backups/$BACKUP_FILE ]; then
    echo "❌ Backup nie istnieje: $BACKUP_FILE"
    exit 1
fi

# Utwórz backup obecnej bazy
cp ~/promag/magazyn.db ~/promag/magazyn.db.before_restore_\$(date +%Y%m%d_%H%M%S)

# Przywróć backup
cp ~/promag/backups/$BACKUP_FILE ~/promag/magazyn.db

echo "✅ Backup przywrócony!"
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "🔄 Restartowanie aplikacji..."
    bash supervisor_restart.sh
    
    echo ""
    echo "=========================="
    echo "✅ Backup przywrócony pomyślnie!"
    echo ""
    echo "Sprawdź aplikację:"
    echo "  https://promag.flavorinthejar.com/"
else
    echo ""
    echo "=========================="
    echo "❌ Błąd podczas przywracania backupu!"
fi
