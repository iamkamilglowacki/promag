# 🔗 Mapowanie Produktów WooCommerce → Magazyn

## 📋 Lista produktów w magazynie:

| ID | Nazwa | Stan |
|----|-------|------|
| 1 | KuraLover | 0 szt. |
| 2 | Ziemniak Rulezzz | 4 szt. |
| 3 | Jabłko, Migdał & Cynamon | 6 szt. |
| 4 | Grill Master | 4 szt. |
| 5 | JajoMania | 4 szt. |
| 6 | PizzaTime | 11 szt. |
| 7 | Ryż Up! | 6 szt. |
| 8 | Lemon Salad Vibes | 2 szt. |
| 9 | Pieczarka & Kura | 12 szt. |
| 10 | Chrzan & Kura | 0 szt. |
| 11 | Musztarda & Kura | 7 szt. |
| 12 | Fame Kura | 10 szt. |
| 13 | Ranczo Kura | 6 szt. |
| 14 | Gruszka & Kura | 0 szt. |
| 15 | Śliwka & Kura | 0 szt. |
| 16 | All Stars | 4 szt. |
| 17 | Ananas Kokos | 2 szt. |
| 18 | Wiśnia Kokos & Malina | 0 szt. |
| 19 | Italiana | 6 szt. |

---

## 🎯 Jak dodać mapowanie:

### Krok 1: Znajdź ID produktu w WooCommerce

1. Zaloguj się do WordPress
2. Przejdź do: **Produkty → Wszystkie produkty**
3. **Najedź myszką** na produkt (NIE klikaj)
4. W dolnym lewym rogu przeglądarki zobaczysz URL typu:
   ```
   .../wp-admin/post.php?post=123&action=edit
   ```
5. Liczba po `post=` to **ID produktu WooCommerce** (np. 123)

### Krok 2: Znajdź odpowiadający produkt w magazynie

Sprawdź powyższą tabelę i znajdź **ID magazynowe** (np. 1 dla KuraLover)

### Krok 3: Dodaj mapowanie

#### Opcja A: Przez skrypt (NAJŁATWIEJ)

```bash
chmod +x dodaj_mapowanie_przyklad.sh
./dodaj_mapowanie_przyklad.sh
```

Skrypt zapyta o:
- ID produktu WooCommerce (np. 123)
- ID produktu magazynowego (np. 1)

#### Opcja B: Ręcznie przez curl

```bash
curl -X POST https://promag.flavorinthejar.com/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{
    "woocommerce_product_id": 123,
    "produkt_id": 1
  }'
```

Zamień:
- `123` → ID z WooCommerce
- `1` → ID z magazynu

---

## 📋 Przykład mapowania wszystkich produktów:

Jeśli Twoje produkty w WooCommerce mają ID od 100 do 118, możesz zmapować wszystkie naraz:

```bash
# KuraLover (WC: 100 → MAG: 1)
curl -X POST https://promag.flavorinthejar.com/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 100, "produkt_id": 1}'

# Ziemniak Rulezzz (WC: 101 → MAG: 2)
curl -X POST https://promag.flavorinthejar.com/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 101, "produkt_id": 2}'

# ... i tak dalej dla pozostałych
```

---

## ✅ Sprawdzenie mapowań:

### Zobacz wszystkie mapowania:
```bash
curl https://promag.flavorinthejar.com/api/woocommerce/mapowania | python3 -m json.tool
```

### Usuń mapowanie (jeśli pomyłka):
```bash
curl -X DELETE https://promag.flavorinthejar.com/api/woocommerce/mapowania/ID_MAPOWANIA
```

---

## 🧪 Test działania:

### 1. Dodaj mapowanie (np. dla produktu #1)
```bash
curl -X POST https://promag.flavorinthejar.com/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 123, "produkt_id": 1}'
```

### 2. Złóż testowe zamówienie w WooCommerce
- Dodaj produkt do koszyka
- Złóż zamówienie
- **Oznacz jako "Ukończone"**

### 3. Sprawdź logi:
```bash
./show_webhook_logs.sh
```

Powinieneś zobaczyć:
```
✅ JSON sparsowany pomyślnie
Zamówienie przetworzone pomyślnie
```

### 4. Sprawdź stan magazynowy:
```bash
curl https://promag.flavorinthejar.com/api/produkty | grep -A 2 "KuraLover"
```

Stan powinien się zmniejszyć!

---

## 🎯 Kiedy webhook aktualizuje magazyn:

✅ **Warunki:**
1. Zamówienie ma status **"completed"** (ukończone)
2. Produkt jest **zmapowany** (WooCommerce ID → Magazyn ID)
3. Produkt ma **wystarczający stan** w magazynie

❌ **Nie zadziała jeśli:**
- Zamówienie ma inny status (oczekujące, w trakcie, itp.)
- Produkt nie jest zmapowany
- Brak produktu na stanie (zwróci błąd w logach)

---

## 📊 Monitoring:

### Sprawdź historię operacji:
```bash
curl https://promag.flavorinthejar.com/api/historia/produkty | python3 -m json.tool | head -50
```

Powinieneś zobaczyć operacje typu `"woocommerce"` z opisem zamówienia.

---

**Gotowe! Teraz dodaj mapowania dla swoich produktów!** 🚀
