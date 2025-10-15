#!/bin/bash

# Skrypt testowy dla API WooCommerce
# Użycie: ./test_woocommerce_api.sh

BASE_URL="http://localhost:5001"

echo "🧪 Testowanie API WooCommerce"
echo "================================"
echo ""

# Test 1: Pobierz listę produktów magazynowych
echo "📦 Test 1: Pobieranie listy produktów magazynowych"
curl -s "${BASE_URL}/api/produkty" | python3 -m json.tool
echo ""
echo ""

# Test 2: Pobierz listę mapowań
echo "🔗 Test 2: Pobieranie listy mapowań WooCommerce"
curl -s "${BASE_URL}/api/woocommerce/mapowania" | python3 -m json.tool
echo ""
echo ""

# Test 3: Dodaj przykładowe mapowanie
echo "➕ Test 3: Dodawanie mapowania (WooCommerce ID 123 -> Produkt ID 1)"
curl -s -X POST "${BASE_URL}/api/woocommerce/mapowania" \
  -H "Content-Type: application/json" \
  -d '{
    "woocommerce_product_id": 123,
    "produkt_id": 1
  }' | python3 -m json.tool
echo ""
echo ""

# Test 4: Pobierz mapowania ponownie
echo "🔗 Test 4: Pobieranie listy mapowań po dodaniu"
curl -s "${BASE_URL}/api/woocommerce/mapowania" | python3 -m json.tool
echo ""
echo ""

# Test 5: Symuluj webhook WooCommerce (zamówienie ukończone)
echo "📨 Test 5: Symulacja webhooka WooCommerce (zamówienie ukończone)"
curl -s -X POST "${BASE_URL}/api/woocommerce/webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 999,
    "status": "completed",
    "line_items": [
      {
        "product_id": 123,
        "quantity": 2,
        "name": "Test Product"
      }
    ]
  }' | python3 -m json.tool
echo ""
echo ""

# Test 6: Sprawdź stan produktu po webhook
echo "📊 Test 6: Sprawdzanie stanu produktów po webhook"
curl -s "${BASE_URL}/api/produkty" | python3 -m json.tool
echo ""
echo ""

# Test 7: Sprawdź historię produktów
echo "📜 Test 7: Sprawdzanie historii produktów"
curl -s "${BASE_URL}/api/historia/produkty" | python3 -m json.tool
echo ""
echo ""

echo "✅ Testy zakończone!"
echo ""
echo "💡 Wskazówki:"
echo "- Jeśli mapowanie już istnieje, usuń je przez DELETE /api/woocommerce/mapowania/{id}"
echo "- Sprawdź czy produkty mają wystarczający stan magazynowy"
echo "- Webhook odejmie produkty tylko jeśli zamówienie ma status 'completed'"
