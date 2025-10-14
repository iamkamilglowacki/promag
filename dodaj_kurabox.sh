#!/bin/bash

# Dodanie KuraBox jako zestawu produktów

echo "📦 Dodawanie KuraBox jako zestawu..."
echo "===================================="
echo ""

API_URL="https://promag.flavorinthejar.com"

# Krok 1: Utwórz mapowanie dla KuraBox jako zestaw
echo "1. Tworzę mapowanie KuraBox (WC #15146)..."

curl -s -X POST "$API_URL/api/woocommerce/mapowania" \
  -H "Content-Type: application/json" \
  -d '{
    "woocommerce_product_id": 15146,
    "jest_zestawem": true
  }' | python3 -m json.tool

echo ""
echo ""

# Krok 2: Pobierz ID utworzonego mapowania
MAPOWANIE_ID=$(curl -s "$API_URL/api/woocommerce/mapowania" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data:
    if m['woocommerce_product_id'] == 15146:
        print(m['id'])
        break
")

if [ -z "$MAPOWANIE_ID" ]; then
    echo "❌ Nie udało się utworzyć mapowania!"
    exit 1
fi

echo "✅ Mapowanie utworzone z ID: $MAPOWANIE_ID"
echo ""

# Krok 3: Dodaj produkty do zestawu
echo "2. Dodaję produkty do zestawu KuraBox..."
echo ""

# KuraBox zawiera:
# - Fame Kura (ID 12)
# - Musztarda & Kura (ID 11)
# - Śliwka & Kura (ID 15)
# - Gruszka & Kura (ID 14)
# - KuraLover (ID 1)
# - Chrzan & Kura (ID 10)
# - Ranczo Kura (ID 13)
# - Pieczarka & Kura (ID 9)

declare -a PRODUKTY=(12 11 15 14 1 10 13 9)
declare -a NAZWY=("Fame Kura" "Musztarda & Kura" "Śliwka & Kura" "Gruszka & Kura" "KuraLover" "Chrzan & Kura" "Ranczo Kura" "Pieczarka & Kura")

for i in "${!PRODUKTY[@]}"; do
    PROD_ID=${PRODUKTY[$i]}
    NAZWA=${NAZWY[$i]}
    
    echo -n "  → Dodaję $NAZWA (ID $PROD_ID)... "
    
    RESPONSE=$(curl -s -X POST "$API_URL/api/woocommerce/zestawy/$MAPOWANIE_ID/produkty" \
        -H "Content-Type: application/json" \
        -d "{\"produkt_id\": $PROD_ID, \"ilosc\": 1}")
    
    if echo "$RESPONSE" | grep -q "id"; then
        echo "✅"
    else
        echo "❌ $RESPONSE"
    fi
    
    sleep 0.2
done

echo ""
echo "===================================="
echo "✅ KuraBox skonfigurowany!"
echo ""
echo "Sprawdź konfigurację:"
echo "curl $API_URL/api/woocommerce/mapowania | python3 -m json.tool | grep -A 20 '15146'"
