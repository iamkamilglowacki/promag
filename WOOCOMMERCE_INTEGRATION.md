# 🔗 Integracja z WooCommerce

Automatyczna synchronizacja stanów magazynowych po zakupach w sklepie WooCommerce.

## 📋 Jak to działa

1. **Mapowanie produktów**: Łączysz produkty WooCommerce z produktami w magazynie
2. **Webhook**: WooCommerce wysyła powiadomienie po każdym zamówieniu
3. **Automatyczna aktualizacja**: System odejmuje sprzedane produkty ze stanu magazynowego
4. **Historia**: Wszystkie operacje są logowane w historii produktów

## ⚙️ Konfiguracja krok po kroku

### Krok 1: Skonfiguruj webhook w WooCommerce

1. Zaloguj się do panelu WordPress/WooCommerce
2. Przejdź do **WooCommerce → Ustawienia → Zaawansowane → Webhooks**
3. Kliknij **Dodaj webhook**
4. Wypełnij formularz:
   - **Nazwa**: `Magazyn - Aktualizacja stanów`
   - **Status**: `Aktywny`
   - **Temat**: `Order completed` (Zamówienie ukończone)
   - **URL dostarczenia**: `http://[TWOJ_IP]:5001/api/woocommerce/webhook`
   - **Sekret**: Wygeneruj losowy ciąg znaków (np. `wc_secret_abc123xyz`)
   - **Wersja API**: `WP REST API Integration v3`
5. Kliknij **Zapisz webhook**

### Krok 2: Dodaj sekret do systemu magazynowego

**Opcja A: Plik .env (zalecane)**

Utwórz plik `.env` w katalogu głównym projektu:
```bash
WOOCOMMERCE_SECRET=wc_secret_abc123xyz
```

**Opcja B: Zmienna środowiskowa**
```bash
export WOOCOMMERCE_SECRET="wc_secret_abc123xyz"
```

**Opcja C: Edytuj start.sh**

Dodaj przed uruchomieniem aplikacji:
```bash
export WOOCOMMERCE_SECRET="wc_secret_abc123xyz"
```

### Krok 3: Uruchom ponownie aplikację

```bash
./start.sh
```

### Krok 4: Zmapuj produkty

Użyj API do dodania mapowań produktów WooCommerce z produktami magazynowymi.

**Przykład dodania mapowania:**
```bash
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{
    "woocommerce_product_id": 123,
    "produkt_id": 1
  }'
```

Gdzie:
- `123` - ID produktu w WooCommerce
- `1` - ID produktu w systemie magazynowym

## 🔍 Jak znaleźć ID produktu WooCommerce

1. W panelu WordPress przejdź do **Produkty**
2. Najedź na produkt - w URL zobaczysz `post=123` - to jest ID produktu
3. Lub kliknij "Edytuj" i sprawdź URL: `post.php?post=123&action=edit`

## 🔍 Jak znaleźć ID produktu magazynowego

Użyj API:
```bash
curl http://localhost:5001/api/produkty
```

Znajdź swój produkt na liście i sprawdź jego `id`.

## 🧪 Testowanie

### Test 1: Sprawdź mapowania
```bash
curl http://localhost:5001/api/woocommerce/mapowania
```

### Test 2: Złóż testowe zamówienie

1. Złóż zamówienie w WooCommerce
2. Oznacz zamówienie jako **"Ukończone"**
3. Sprawdź w systemie magazynowym czy stan się zmniejszył:
```bash
curl http://localhost:5001/api/produkty
```
4. Sprawdź historię produktów:
```bash
curl http://localhost:5001/api/historia/produkty
```

Powinna pojawić się operacja typu "woocommerce".

### Test 3: Sprawdź logi WooCommerce

W panelu WordPress:
**WooCommerce → Status → Logi** - wybierz log webhooków

## 📊 API Endpoints

### Mapowania produktów

**Pobierz wszystkie mapowania**
```http
GET /api/woocommerce/mapowania
```

Odpowiedź:
```json
[
  {
    "id": 1,
    "woocommerce_product_id": 123,
    "produkt_id": 1,
    "produkt_nazwa": "KuraLover",
    "data_utworzenia": "2025-10-11 12:00:00"
  }
]
```

**Dodaj mapowanie**
```http
POST /api/woocommerce/mapowania
Content-Type: application/json

{
  "woocommerce_product_id": 123,
  "produkt_id": 1
}
```

**Usuń mapowanie**
```http
DELETE /api/woocommerce/mapowania/{id}
```

### Webhook

**Endpoint dla WooCommerce**
```http
POST /api/woocommerce/webhook
```

Ten endpoint jest wywoływany automatycznie przez WooCommerce.

Przykładowa odpowiedź:
```json
{
  "message": "Zamówienie przetworzone pomyślnie",
  "order_id": 456,
  "updated_products": [
    {
      "produkt_nazwa": "KuraLover",
      "ilosc": 2,
      "stan_przed": 50,
      "stan_po": 48
    }
  ],
  "errors": null
}
```

## 🔒 Bezpieczeństwo

### ✅ Dobre praktyki

- **Zawsze używaj sekretu** - chroni przed nieautoryzowanymi żądaniami
- **Używaj HTTPS w produkcji** - szyfruje komunikację
- **Regularnie zmieniaj sekret** - zwiększa bezpieczeństwo
- **Monitoruj logi** - wykrywaj podejrzane aktywności

### 🌐 Dostęp z internetu (produkcja)

Jeśli serwer jest lokalny, musisz udostępnić go w internecie:

**Opcja 1: ngrok (do testów)**
```bash
ngrok http 5001
```
Użyj URL z ngrok jako URL webhook w WooCommerce.

**Opcja 2: Serwer produkcyjny**
- Postaw aplikację na serwerze z publicznym IP
- Skonfiguruj HTTPS (Let's Encrypt)
- Użyj nginx jako reverse proxy

## 🐛 Rozwiązywanie problemów

### Problem: Webhook nie działa

**Rozwiązanie:**
1. Sprawdź czy port 5001 jest otwarty w firewall
2. Sprawdź logi WooCommerce: **WooCommerce → Status → Logi**
3. Sprawdź czy URL jest dostępny z internetu
4. Przetestuj endpoint ręcznie:
```bash
curl -X POST http://localhost:5001/api/woocommerce/webhook \
  -H "Content-Type: application/json" \
  -d '{"status":"completed","id":999,"line_items":[]}'
```

### Problem: Stany się nie aktualizują

**Rozwiązanie:**
1. Sprawdź czy produkty są poprawnie zmapowane:
```bash
curl http://localhost:5001/api/woocommerce/mapowania
```
2. Sprawdź logi aplikacji Flask
3. Upewnij się że sekret jest poprawnie skonfigurowany
4. Sprawdź czy zamówienie ma status "completed"

### Problem: Błąd "Nieprawidłowy podpis"

**Rozwiązanie:**
1. Sprawdź czy sekret w `.env` jest identyczny z sekretem w WooCommerce
2. Usuń spacje na początku/końcu sekretu
3. Upewnij się że plik `.env` jest w głównym katalogu projektu
4. Uruchom ponownie aplikację po zmianie `.env`

### Problem: "Brak mapowania dla produktu"

**Rozwiązanie:**
1. Dodaj mapowanie dla tego produktu:
```bash
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 123, "produkt_id": 1}'
```
2. Sprawdź czy ID produktu WooCommerce jest poprawne
3. Lista mapowań: `curl http://localhost:5001/api/woocommerce/mapowania`

### Problem: "Niewystarczający stan"

**Rozwiązanie:**
1. Sprawdź stan magazynowy produktu:
```bash
curl http://localhost:5001/api/produkty
```
2. Uzupełnij stan przez produkcję lub korektę
3. Webhook nie odejmie produktu jeśli nie ma go na stanie (bezpieczeństwo)

## 📝 Przykładowy flow

1. **Klient kupuje produkt** w sklepie WooCommerce (np. "KuraLover", 2 sztuki)
2. **Zamówienie zostaje opłacone** i oznaczone jako "Ukończone"
3. **WooCommerce wysyła webhook** do systemu magazynowego
4. **System sprawdza mapowanie**: WooCommerce produkt #123 → Magazyn produkt #1
5. **System sprawdza dostępność**: KuraLover ma 50 szt. na stanie
6. **System odejmuje**: 50 - 2 = 48 szt.
7. **System zapisuje historię**: "Zamówienie WooCommerce #456 - sprzedano 2 szt."
8. **System zwraca potwierdzenie** do WooCommerce

## 🎯 Korzyści

✅ **Automatyzacja** - brak ręcznego wprowadzania sprzedaży  
✅ **Dokładność** - eliminacja błędów ludzkich  
✅ **Historia** - pełna śledzalność operacji  
✅ **Bezpieczeństwo** - weryfikacja podpisu webhook  
✅ **Skalowalność** - obsługa wielu produktów jednocześnie  
✅ **Walidacja** - sprawdzanie dostępności przed odjęciem  

## 📦 Przykładowe mapowania

Jeśli masz następujące produkty:

**W systemie magazynowym:**
- ID 1: KuraLover
- ID 2: Ziemniak Rulezzz

**W WooCommerce:**
- ID 123: Przyprawa do kurczaka (KuraLover)
- ID 456: Przyprawa do ziemniaków (Ziemniak Rulezzz)

**Dodaj mapowania:**
```bash
# Mapowanie 1
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 123, "produkt_id": 1}'

# Mapowanie 2
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 456, "produkt_id": 2}'
```

## 📞 Wsparcie

Jeśli masz problemy z integracją:
1. Sprawdź logi aplikacji Flask
2. Sprawdź logi WooCommerce
3. Przetestuj endpoint ręcznie
4. Sprawdź konfigurację sekretu
5. Sprawdź mapowania produktów

## 🚀 Następne kroki

Po skonfigurowaniu integracji możesz:
1. Dodać powiadomienia email o niskich stanach
2. Stworzyć dashboard z statystykami sprzedaży
3. Zintegrować z innymi platformami e-commerce
4. Dodać automatyczne zamówienia surowców
