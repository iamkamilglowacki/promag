#!/bin/bash

# Skrypt do łatwego dodawania mapowań produktów WooCommerce
# Użycie: ./dodaj_mapowanie.sh

echo "🔗 Dodawanie mapowania produktu WooCommerce"
echo "============================================"
echo ""

# Pokaż dostępne produkty magazynowe
echo "📦 Dostępne produkty w magazynie:"
echo ""
curl -s http://localhost:5001/api/produkty | python3 -c "
import sys, json
produkty = json.load(sys.stdin)
for p in produkty:
    print(f\"  ID: {p['id']:2d} | {p['nazwa']:30s} | Stan: {p['stan_magazynowy']} szt.\")
"
echo ""
echo "============================================"
echo ""

# Pobierz dane od użytkownika
read -p "Podaj ID produktu WooCommerce: " wc_id
read -p "Podaj ID produktu magazynowego: " mag_id

echo ""
echo "Dodaję mapowanie..."
echo ""

# Dodaj mapowanie
response=$(curl -s -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d "{\"woocommerce_product_id\": $wc_id, \"produkt_id\": $mag_id}")

# Sprawdź czy się udało
if echo "$response" | grep -q "error"; then
    echo "❌ Błąd!"
    echo "$response" | python3 -m json.tool
else
    echo "✅ Mapowanie dodane pomyślnie!"
    echo ""
    echo "$response" | python3 -m json.tool
fi

echo ""
echo "============================================"
echo ""
echo "📋 Wszystkie mapowania:"
echo ""
curl -s http://localhost:5001/api/woocommerce/mapowania | python3 -c "
import sys, json
mapowania = json.load(sys.stdin)
if not mapowania:
    print('  Brak mapowań')
else:
    for m in mapowania:
        print(f\"  WooCommerce #{m['woocommerce_product_id']} → {m['produkt_nazwa']} (ID: {m['produkt_id']})\")
"
echo ""
