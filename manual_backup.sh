#!/bin/bash

# Ręczny backup bazy danych

echo "📦 Tworzenie ręcznego backupu..."
echo "================================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'
~/promag/backup_database.sh
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "================================="
    echo "✅ Backup utworzony!"
    echo ""
    echo "Sprawdź backupy:"
    ssh -p 65002 u923457281@46.17.175.219 "ls -lh ~/promag/backups/ | tail -5"
else
    echo ""
    echo "================================="
    echo "❌ Błąd podczas tworzenia backupu!"
fi
