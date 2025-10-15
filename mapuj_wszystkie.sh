#!/bin/bash

# Automatyczne mapowanie wszystkich produktów WooCommerce → Magazyn

echo "🔗 Mapowanie wszystkich produktów..."
echo "===================================="
echo ""

API_URL="https://promag.flavorinthejar.com/api/woocommerce/mapowania"

# Mapowania: WooCommerce ID → Magazyn ID
declare -A MAPOWANIA=(
    [16]=1      # Kura Lover → KuraLover
    [157]=2     # Ziemniak Rulezzz → Ziemniak Rulezzz
    [12406]=3   # Jabłko Migdał Cynamon → Jabłko, Migdał & Cynamon
    [127]=4     # Grill Master → Grill Master
    [166]=5     # Jajo Mania → JajoMania
    [154]=6     # Pizza Time → PizzaTime
    [133]=7     # Ryż Up! → Ryż Up!
    [121]=8     # Lemon Salad Vibes → Lemon Salad Vibes
    [15031]=9   # Pieczarka & Kura → Pieczarka & Kura
    [15022]=10  # Chrzan & Kura → Chrzan & Kura
    [15037]=11  # Musztarda & Kura → Musztarda & Kura
    [15048]=12  # Fame Kura → Fame Kura
    [15054]=13  # Ranczo Kura → Ranczo Kura
    [12398]=14  # Gruszka & Kura → Gruszka & Kura
    [12400]=15  # Śliwka & Kura → Śliwka & Kura
    [12366]=16  # All Stars → All Stars
    # Brak: Ananas Kokos (ID 17)
    [12404]=18  # Wiśnia, Kokos & Malina → Wiśnia Kokos & Malina
    [160]=19    # Italiana → Italiana
)

SUCCESS=0
FAILED=0

for WC_ID in "${!MAPOWANIA[@]}"; do
    MAG_ID=${MAPOWANIA[$WC_ID]}
    
    echo -n "Mapuję WooCommerce #$WC_ID → Magazyn #$MAG_ID ... "
    
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{\"woocommerce_product_id\": $WC_ID, \"produkt_id\": $MAG_ID}")
    
    if echo "$RESPONSE" | grep -q "id"; then
        echo "✅"
        ((SUCCESS++))
    else
        echo "❌ $RESPONSE"
        ((FAILED++))
    fi
    
    sleep 0.2
done

echo ""
echo "===================================="
echo "✅ Zmapowano: $SUCCESS produktów"
echo "❌ Błędy: $FAILED"
echo ""
echo "Sprawdź mapowania:"
echo "curl https://promag.flavorinthejar.com/api/woocommerce/mapowania | python3 -m json.tool"
