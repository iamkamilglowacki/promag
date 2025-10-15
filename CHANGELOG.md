# Changelog

## [1.1.0] - 2025-10-11

### ✨ Nowe funkcje

#### 🔗 Integracja WooCommerce
- **Automatyczna synchronizacja stanów** - system automatycznie odejmuje produkty ze stanu magazynowego po zakupach w WooCommerce
- **Mapowanie produktów** - możliwość łączenia produktów WooCommerce z produktami magazynowymi
- **Webhook endpoint** - odbieranie powiadomień o zamówieniach z WooCommerce
- **Weryfikacja bezpieczeństwa** - podpis HMAC SHA256 dla webhooków
- **Historia operacji** - wszystkie operacje WooCommerce są logowane w historii produktów

#### 📊 Nowe API Endpoints
- `GET /api/woocommerce/mapowania` - lista mapowań produktów
- `POST /api/woocommerce/mapowania` - dodawanie mapowania
- `DELETE /api/woocommerce/mapowania/<id>` - usuwanie mapowania
- `POST /api/woocommerce/webhook` - endpoint dla webhooków WooCommerce

#### 📝 Nowa dokumentacja
- `WOOCOMMERCE_INTEGRATION.md` - pełna instrukcja integracji
- `QUICKSTART_WOOCOMMERCE.md` - szybki start
- `test_woocommerce_api.sh` - skrypt testowy
- `webhook_example.json` - przykładowy payload webhooka
- `.env.example` - przykładowa konfiguracja

### 🗄️ Baza danych

#### Nowa tabela
- `woo_commerce_mapowanie` - mapowanie produktów WooCommerce na produkty magazynowe
  - `id` - klucz główny
  - `woocommerce_product_id` - ID produktu w WooCommerce (unique)
  - `produkt_id` - ID produktu w magazynie (foreign key)
  - `data_utworzenia` - data utworzenia mapowania

### 🔧 Zmiany techniczne

#### Nowe importy
- `hmac` - weryfikacja podpisu webhooków
- `hashlib` - hashowanie SHA256
- `json` - parsowanie payloadów

#### Nowa konfiguracja
- `WOOCOMMERCE_SECRET` - sekret do weryfikacji webhooków (zmienna środowiskowa)

### 📚 Dokumentacja

#### Zaktualizowane pliki
- `README.md` - dodano sekcję o integracji WooCommerce
- Zaktualizowano listę funkcjonalności
- Dodano informacje o nowych tabelach bazy danych
- Dodano listę plików projektu

### 🔒 Bezpieczeństwo

- Weryfikacja podpisu HMAC SHA256 dla webhooków
- Sekret przechowywany w zmiennej środowiskowej
- Walidacja dostępności produktów przed odjęciem stanu
- Obsługa błędów i rollback transakcji

### 🧪 Testowanie

- Skrypt testowy `test_woocommerce_api.sh`
- Przykładowy payload webhooka
- Instrukcje testowania lokalnego i z WooCommerce

---

## [1.0.0] - 2025-10-10

### ✨ Funkcje początkowe

- Zarządzanie surowcami
- Zarządzanie produktami
- Receptury produktów
- Dostawy surowców
- Produkcja mieszanek
- Cykle produkcyjne z walidacją
- Potencjał produkcyjny
- Historia operacji
- Dashboard
- Dostęp wielourządzeniowy
