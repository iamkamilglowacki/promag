#!/bin/bash

# Automatyczny backup bazy danych

echo "🔄 Tworzenie backupu bazy danych..."

# Katalog na backupy
BACKUP_DIR="$HOME/promag/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="magazyn_backup_$DATE.db"

# Utwórz katalog jeśli nie istnieje
mkdir -p "$BACKUP_DIR"

# Skopiuj bazę danych
cp "$HOME/promag/magazyn.db" "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup utworzony: $BACKUP_FILE"
    
    # Usuń backupy starsze niż 30 dni
    find "$BACKUP_DIR" -name "magazyn_backup_*.db" -mtime +30 -delete
    
    # Pokaż liczbę backupów
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/magazyn_backup_*.db 2>/dev/null | wc -l)
    echo "📊 Liczba backupów: $BACKUP_COUNT"
    
    # Pokaż rozmiar
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "💾 Rozmiar: $BACKUP_SIZE"
else
    echo "❌ Błąd podczas tworzenia backupu!"
    exit 1
fi
