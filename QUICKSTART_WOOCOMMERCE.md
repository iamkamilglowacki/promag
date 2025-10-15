# 🚀 Szybki start - Integracja WooCommerce

## Krok 1: Uruchom aplikację (jeśli nie działa)

```bash
./start.sh
```

## Krok 2: Utwórz plik .env

```bash
cp .env.example .env
```

Edytuj plik `.env` i ustaw sekret:
```bash
WOOCOMMERCE_SECRET=twoj_losowy_sekret_tutaj
```

**Przykład:**
```bash
WOOCOMMERCE_SECRET=wc_secret_abc123xyz456
```

## Krok 3: Uruchom ponownie aplikację

```bash
./start.sh
```

## Krok 4: Znajdź ID swoich produktów

### Produkty magazynowe:
```bash
curl http://localhost:5001/api/produkty
```

Przykładowa odpowiedź:
```json
[
  {
    "id": 1,
    "nazwa": "KuraLover",
    "stan_magazynowy": 50
  },
  {
    "id": 2,
    "nazwa": "Ziemniak Rulezzz",
    "stan_magazynowy": 30
  }
]
```

### Produkty WooCommerce:

W panelu WordPress:
1. Przejdź do **Produkty**
2. Najedź na produkt
3. W URL zobaczysz: `post=123` ← to jest ID

## Krok 5: Dodaj mapowania

Dla każdego produktu wykonaj:

```bash
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{
    "woocommerce_product_id": 123,
    "produkt_id": 1
  }'
```

**Zamień:**
- `123` → ID produktu w WooCommerce
- `1` → ID produktu w magazynie

## Krok 6: Skonfiguruj webhook w WooCommerce

1. Zaloguj się do WordPress
2. **WooCommerce → Ustawienia → Zaawansowane → Webhooks**
3. Kliknij **Dodaj webhook**
4. Wypełnij:
   - **Nazwa**: Magazyn - Aktualizacja stanów
   - **Status**: Aktywny
   - **Temat**: Order completed
   - **URL**: `http://[TWOJ_IP]:5001/api/woocommerce/webhook`
   - **Sekret**: (ten sam co w `.env`)
   - **Wersja API**: WP REST API Integration v3
5. **Zapisz**

## Krok 7: Znajdź swój IP

**macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Lub:**
```bash
hostname -I
```

## Krok 8: Testowanie

### Test lokalny (bez WooCommerce):

```bash
./test_woocommerce_api.sh
```

### Test z WooCommerce:

1. Złóż testowe zamówienie
2. Oznacz jako **"Ukończone"**
3. Sprawdź stany:
```bash
curl http://localhost:5001/api/produkty
```

4. Sprawdź historię:
```bash
curl http://localhost:5001/api/historia/produkty
```

## ✅ Gotowe!

System jest skonfigurowany. Każde ukończone zamówienie w WooCommerce automatycznie odejmie produkty ze stanu magazynowego.

## 🆘 Problemy?

### Webhook nie działa

1. Sprawdź logi WooCommerce: **WooCommerce → Status → Logi**
2. Sprawdź czy aplikacja działa: `curl http://localhost:5001/api/produkty`
3. Sprawdź czy sekret jest poprawny
4. Sprawdź firewall

### Stany się nie aktualizują

1. Sprawdź mapowania:
```bash
curl http://localhost:5001/api/woocommerce/mapowania
```

2. Sprawdź czy produkt ma stan:
```bash
curl http://localhost:5001/api/produkty
```

3. Sprawdź logi aplikacji

## 📚 Więcej informacji

Zobacz plik `WOOCOMMERCE_INTEGRATION.md` dla pełnej dokumentacji.
