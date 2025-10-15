#!/bin/bash

# Przykład dodawania mapowania produktu WooCommerce → Magazyn

echo "📋 Dodawanie mapowania produktu"
echo "================================"
echo ""
echo "KROK 1: Znajdź ID produktu w WooCommerce"
echo "  - WordPress → Produkty → najedź na produkt"
echo "  - W URL: post=123 ← to jest ID"
echo ""
echo "KROK 2: Znajdź ID produktu w magazynie"
echo "  - ID 1: KuraLover"
echo "  - ID 2: Ziemniak Rulezzz"
echo ""
echo "KROK 3: Dodaj mapowanie"
echo ""

read -p "Podaj ID produktu WooCommerce: " WC_ID
read -p "Podaj ID produktu magazynowego (1 lub 2): " MAG_ID

echo ""
echo "Dodaję mapowanie: WooCommerce #$WC_ID → Magazyn #$MAG_ID"
echo ""

curl -X POST https://promag.flavorinthejar.com/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d "{
    \"woocommerce_product_id\": $WC_ID,
    \"produkt_id\": $MAG_ID
  }" | python3 -m json.tool

echo ""
echo ""
echo "✅ Mapowanie dodane!"
echo ""
echo "Sprawdź wszystkie mapowania:"
echo "curl https://promag.flavorinthejar.com/api/woocommerce/mapowania"
