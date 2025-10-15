#!/usr/bin/env python3
"""
Skrypt do dodania KuraBox jako zestawu produktów
Uruchom na serwerze: python3 dodaj_kurabox_sql.py
"""

import sqlite3
from datetime import datetime

# Połącz z bazą danych
conn = sqlite3.connect('/home/u923457281/promag/instance/magazyn.db')
cursor = conn.cursor()

print("📦 Dodawanie KuraBox jako zestawu...")
print("=" * 60)

# Krok 1: Dodaj kolumny jeśli nie istnieją
print("\n1. Aktualizacja struktury bazy danych...")
try:
    cursor.execute("ALTER TABLE woo_commerce_mapowanie ADD COLUMN jest_zestawem BOOLEAN DEFAULT 0")
    print("  ✅ Dodano kolumnę 'jest_zestawem'")
except sqlite3.OperationalError:
    print("  ℹ️  Kolumna 'jest_zestawem' już istnieje")

# SQLite nie pozwala na ALTER COLUMN, więc musimy przebudować tabelę
print("\n  Sprawdzanie struktury tabeli...")
cursor.execute("PRAGMA table_info(woo_commerce_mapowanie)")
columns = cursor.execute("PRAGMA table_info(woo_commerce_mapowanie)").fetchall()
print(f"  Kolumny: {[col[1] for col in columns]}")

# Krok 2: Utwórz tabelę dla pozycji zestawu
print("\n2. Tworzenie tabeli woo_commerce_zestaw_pozycja...")
cursor.execute("""
CREATE TABLE IF NOT EXISTS woo_commerce_zestaw_pozycja (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mapowanie_id INTEGER NOT NULL,
    produkt_id INTEGER NOT NULL,
    ilosc INTEGER DEFAULT 1,
    FOREIGN KEY (mapowanie_id) REFERENCES woo_commerce_mapowanie(id),
    FOREIGN KEY (produkt_id) REFERENCES produkt(id)
)
""")
print("  ✅ Tabela utworzona")

# Krok 3: Dodaj mapowanie dla KuraBox
print("\n3. Dodawanie mapowania KuraBox (WC #15146)...")
# Używamy produkt_id=1 jako placeholder (będzie ignorowane bo jest_zestawem=1)
cursor.execute("""
INSERT OR REPLACE INTO woo_commerce_mapowanie 
(woocommerce_product_id, produkt_id, jest_zestawem, data_utworzenia)
VALUES (15146, 1, 1, ?)
""", (datetime.now(),))

mapowanie_id = cursor.lastrowid
print(f"  ✅ Mapowanie utworzone z ID: {mapowanie_id}")

# Krok 4: Dodaj produkty do zestawu
print("\n4. Dodawanie produktów do KuraBox...")

produkty_w_zestawie = [
    (12, "Fame Kura"),
    (11, "Musztarda & Kura"),
    (15, "Śliwka & Kura"),
    (14, "Gruszka & Kura"),
    (1, "KuraLover"),
    (10, "Chrzan & Kura"),
    (13, "Ranczo Kura"),
    (9, "Pieczarka & Kura")
]

for produkt_id, nazwa in produkty_w_zestawie:
    cursor.execute("""
    INSERT INTO woo_commerce_zestaw_pozycja (mapowanie_id, produkt_id, ilosc)
    VALUES (?, ?, 1)
    """, (mapowanie_id, produkt_id))
    print(f"  ✅ Dodano: {nazwa} (ID {produkt_id})")

# Zapisz zmiany
conn.commit()
conn.close()

print("\n" + "=" * 60)
print("✅ KuraBox skonfigurowany pomyślnie!")
print("\nKuraBox (WC #15146) zawiera:")
for _, nazwa in produkty_w_zestawie:
    print(f"  • {nazwa}")
print("\nTeraz gdy ktoś zamówi KuraBox, system automatycznie odejmie")
print("po 1 sztuce każdego z tych produktów!")
