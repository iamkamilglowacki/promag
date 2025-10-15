# 🛒 Konfiguracja integracji z Twoim sklepem WooCommerce

## ✅ Krok 1: Sekret został wygenerowany!

Twój sekret znajduje się w pliku `.env`:
```
WOOCOMMERCE_SECRET=wc_secret_715a8339c6ae64451fca0b5348a57f4a
```

**⚠️ WAŻNE:** Skopiuj ten sekret - będzie potrzebny w WooCommerce!

---

## 🌐 Krok 2: Konfiguracja webhooka w WooCommerce

### A. Zaloguj się do WordPress

1. Przejdź do panelu administracyjnego WordPress
2. Zaloguj się jako administrator

### B. Przejdź do ustawień webhooków

Ścieżka: **WooCommerce → Ustawienia → Zaawansowane → Webhooks**

### C. Dodaj nowy webhook

Kliknij przycisk **"Dodaj webhook"** i wypełnij formularz:

#### 📝 Formularz webhooka:

**Nazwa:**
```
Magazyn - Aktualizacja stanów
```

**Status:**
```
Aktywny
```

**Temat (Topic):**
```
Order completed
```
(Wybierz z listy rozwijanej: "Zamówienie ukończone" lub "Order completed")

**URL dostarczenia (Delivery URL):**
```
http://192.168.0.108:5001/api/woocommerce/webhook
```

**Sekret (Secret):**
```
wc_secret_715a8339c6ae64451fca0b5348a57f4a
```
(Skopiuj dokładnie z pliku `.env`)

**Wersja API:**
```
WP REST API Integration v3
```

### D. Zapisz webhook

Kliknij **"Zapisz webhook"**

---

## 🔗 Krok 3: Mapowanie produktów

Teraz musisz połączyć produkty z WooCommerce z produktami w magazynie.

### A. Znajdź ID produktów WooCommerce

W WordPress:
1. Przejdź do **Produkty → Wszystkie produkty**
2. Najedź myszką na produkt
3. W dolnym lewym rogu przeglądarki zobaczysz URL typu:
   ```
   post.php?post=123&action=edit
   ```
   Liczba `123` to ID produktu WooCommerce

### B. Znajdź ID produktów magazynowych

Otwórz terminal i wykonaj:
```bash
curl http://localhost:5001/api/produkty
```

Zobaczysz listę produktów, np.:
```json
[
  {
    "id": 1,
    "nazwa": "KuraLover",
    "stan_magazynowy": 0
  },
  {
    "id": 2,
    "nazwa": "Ziemniak Rulezzz",
    "stan_magazynowy": 4
  }
]
```

### C. Dodaj mapowania

Dla każdego produktu wykonaj komendę:

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

**Przykład:**
Jeśli w WooCommerce masz:
- Produkt "Przyprawa do kurczaka" (ID: 456)

A w magazynie masz:
- Produkt "KuraLover" (ID: 1)

To wykonaj:
```bash
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{
    "woocommerce_product_id": 456,
    "produkt_id": 1
  }'
```

### D. Sprawdź mapowania

```bash
curl http://localhost:5001/api/woocommerce/mapowania
```

---

## 🧪 Krok 4: Testowanie

### Test 1: Złóż testowe zamówienie

1. W swoim sklepie WooCommerce złóż zamówienie
2. Opłać zamówienie (lub oznacz jako opłacone)
3. **Oznacz zamówienie jako "Ukończone"**

### Test 2: Sprawdź stany magazynowe

```bash
curl http://localhost:5001/api/produkty
```

Stan powinien się zmniejszyć!

### Test 3: Sprawdź historię

```bash
curl http://localhost:5001/api/historia/produkty
```

Powinna pojawić się operacja typu "woocommerce".

### Test 4: Sprawdź logi WooCommerce

W WordPress:
**WooCommerce → Status → Logi**

Wybierz log webhooków i sprawdź czy są błędy.

---

## 🌍 Dostęp z internetu (jeśli sklep jest online)

Jeśli Twój sklep WooCommerce jest w internecie, a aplikacja magazynowa jest lokalna, musisz udostępnić aplikację w internecie.

### Opcja 1: ngrok (szybkie, do testów)

```bash
# Zainstaluj ngrok
brew install ngrok

# Uruchom tunel
ngrok http 5001
```

Ngrok pokaże publiczny URL, np.:
```
https://abc123.ngrok.io
```

Użyj tego URL w webhooku:
```
https://abc123.ngrok.io/api/woocommerce/webhook
```

### Opcja 2: Serwer produkcyjny (zalecane)

Postaw aplikację na serwerze VPS z publicznym IP i HTTPS.

---

## 📊 Podsumowanie konfiguracji

### ✅ Co masz już skonfigurowane:

- [x] Sekret wygenerowany: `wc_secret_715a8339c6ae64451fca0b5348a57f4a`
- [x] Plik `.env` utworzony
- [x] Aplikacja działa na: `http://192.168.0.108:5001`

### 📝 Co musisz jeszcze zrobić:

- [ ] Skonfigurować webhook w WooCommerce
- [ ] Zmapować produkty
- [ ] Przetestować z zamówieniem

---

## 🆘 Pomoc

### Webhook nie działa?

1. Sprawdź czy aplikacja działa:
   ```bash
   curl http://localhost:5001/api/produkty
   ```

2. Sprawdź logi WooCommerce (WordPress → WooCommerce → Status → Logi)

3. Sprawdź czy sekret jest identyczny w `.env` i WooCommerce

### Stany się nie aktualizują?

1. Sprawdź mapowania:
   ```bash
   curl http://localhost:5001/api/woocommerce/mapowania
   ```

2. Sprawdź czy zamówienie ma status "completed"

3. Sprawdź czy produkt ma wystarczający stan

---

## 📞 Kontakt

Jeśli masz problemy, sprawdź:
- `WOOCOMMERCE_INTEGRATION.md` - pełna dokumentacja
- `QUICKSTART_WOOCOMMERCE.md` - szybki start
- Logi aplikacji Flask

---

## 🎯 Gotowe!

Po wykonaniu tych kroków, każde ukończone zamówienie w WooCommerce automatycznie odejmie produkty ze stanu magazynowego!
