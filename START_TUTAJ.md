# 🚀 START TUTAJ - Przewodnik szybkiego startu

## 👋 Witaj w systemie magazynowym!

Ten przewodnik pomoże Ci rozpocząć pracę z nowymi funkcjami.

---

## 📋 Spis treści

1. [Uruchomienie aplikacji](#uruchomienie)
2. [Nowe funkcje](#nowe-funkcje)
3. [Integracja WooCommerce](#woocommerce)
4. [Najczęstsze pytania](#faq)

---

## 🎯 Uruchomienie {#uruchomienie}

### Szybki start:
```bash
cd /Users/kamilglowacki/Desktop/MagazynProdukcja
./start.sh
```

Aplikacja uruchomi się na: **http://localhost:5001**

---

## ✨ Nowe funkcje {#nowe-funkcje}

### 1. **Hover na tabelach** 🖱️
- Najedź myszką na rząd w tabeli
- Rząd zmieni kolor i się powiększy
- Działa na wszystkich tabelach

### 2. **Zaznaczanie rzędów** ✅
- Kliknij na rząd w tabeli
- Rząd zaznaczy się na **niebiesko**
- Kliknij ponownie aby odznaczyć
- Możesz zaznaczyć wiele rzędów

**Gdzie:** Zakładki Surowce i Produkty

### 3. **Sortowanie tabel** 🔢
- Kliknij na nagłówek **"Stan (g)"** lub **"Stan (szt.)"**
- Tabela posortuje się rosnąco ↑
- Kliknij ponownie dla sortowania malejącego ↓
- Kliknij trzeci raz aby wrócić do domyślnej kolejności

**Gdzie:** Zakładki Surowce i Produkty

### 4. **Kolumna "Maks. produkcja"** 📊
- Nowa kolumna w tabeli Produkty
- Pokazuje ile słoików możesz wyprodukować
- Kolorowanie: 🔴 niska, 🟠 średnia, 🟢 wysoka
- Sortowalna (kliknij na nagłówek)

**Gdzie:** Zakładka Produkty

### 5. **Szczegóły surowców** ℹ️
- Ikona ℹ️ obok wartości "Maks. produkcja"
- Kliknij aby zobaczyć szczegóły wszystkich surowców
- Tabela pokazuje:
  - Stan dostępny
  - Zużycie na słoik
  - Ile słoików możesz wyprodukować
- Ograniczający surowiec wyróżniony na **czerwono**

**Gdzie:** Zakładka Produkty → kliknij ikonę ℹ️

---

## 🛒 Integracja WooCommerce {#woocommerce}

### Szybka konfiguracja:

#### Krok 1: Utwórz plik .env
```bash
cp .env.example .env
```

Edytuj `.env` i ustaw sekret:
```
WOOCOMMERCE_SECRET=twoj_losowy_sekret
```

#### Krok 2: Uruchom ponownie
```bash
./start.sh
```

#### Krok 3: Skonfiguruj webhook w WooCommerce

W WordPress:
1. **WooCommerce → Ustawienia → Zaawansowane → Webhooks**
2. Kliknij **"Dodaj webhook"**
3. Wypełnij:
   - **Nazwa:** Magazyn - Aktualizacja stanów
   - **Status:** Aktywny
   - **Temat:** Order completed
   - **URL:** `http://[TWOJ_IP]:5001/api/woocommerce/webhook`
   - **Sekret:** (skopiuj z `.env`)
   - **Wersja API:** WP REST API Integration v3

#### Krok 4: Dodaj mapowania produktów
```bash
./dodaj_mapowanie.sh
```

Lub ręcznie:
```bash
curl -X POST http://localhost:5001/api/woocommerce/mapowania \
  -H "Content-Type: application/json" \
  -d '{"woocommerce_product_id": 123, "produkt_id": 1}'
```

#### Krok 5: Testuj!
```bash
./test_woocommerce_api.sh
```

### Szczegółowa dokumentacja:
- 📖 `QUICKSTART_WOOCOMMERCE.md` - szybki start
- 📖 `WOOCOMMERCE_INTEGRATION.md` - pełna instrukcja
- 📖 `INSTRUKCJA_KROK_PO_KROKU.txt` - wizualny przewodnik

---

## ❓ Najczęstsze pytania {#faq}

### Jak znaleźć produkty z najmniejszym stanem?
1. Przejdź do zakładki **Produkty**
2. Kliknij na nagłówek **"Stan (szt.)"**
3. Produkty posortują się od najmniejszego stanu

### Jak sprawdzić którego surowca brakuje?
1. Przejdź do zakładki **Produkty**
2. Znajdź ikonę ℹ️ obok "Maks. produkcja"
3. Kliknij na ikonę
4. Pierwszy rząd (czerwony) to ograniczający surowiec

### Jak dodać mapowanie produktu WooCommerce?
```bash
./dodaj_mapowanie.sh
```

Lub zobacz: `QUICKSTART_WOOCOMMERCE.md`

### Jak przetestować webhook WooCommerce?
```bash
./test_woocommerce_api.sh
```

### Gdzie znajdę dokumentację?
- `NOWE_FUNKCJE.md` - nowe funkcje UI
- `SZCZEGOLY_SUROWCOW.md` - szczegóły surowców
- `WOOCOMMERCE_INTEGRATION.md` - integracja WooCommerce
- `PODSUMOWANIE_SESJI.md` - wszystkie zmiany

---

## 🎯 Szybkie akcje

### Sprawdź stany produktów:
```bash
curl http://localhost:5001/api/produkty
```

### Sprawdź mapowania WooCommerce:
```bash
curl http://localhost:5001/api/woocommerce/mapowania
```

### Sprawdź historię operacji:
```bash
curl http://localhost:5001/api/historia/produkty
```

---

## 📚 Pełna dokumentacja

### Funkcje UI:
- `NOWE_FUNKCJE.md` - hover, zaznaczanie, sortowanie
- `SZCZEGOLY_SUROWCOW.md` - szczegóły surowców
- `ZMIANY_POTENCJAL.md` - kolumna "Maks. produkcja"

### WooCommerce:
- `QUICKSTART_WOOCOMMERCE.md` - szybki start
- `WOOCOMMERCE_INTEGRATION.md` - pełna instrukcja
- `KONFIGURACJA_SKLEPU.md` - szczegółowa konfiguracja
- `INSTRUKCJA_KROK_PO_KROKU.txt` - wizualny przewodnik

### Ogólne:
- `CHANGELOG.md` - historia zmian
- `PODSUMOWANIE_SESJI.md` - wszystkie zmiany z sesji
- `README.md` - główna dokumentacja

---

## 🆘 Pomoc

### Problem z uruchomieniem?
```bash
# Sprawdź czy port 5001 jest wolny
lsof -i :5001

# Jeśli zajęty, zabij proces
pkill -f "python.*app.py"

# Uruchom ponownie
./start.sh
```

### Problem z webhookiem WooCommerce?
1. Sprawdź logi WooCommerce: **WooCommerce → Status → Logi**
2. Sprawdź czy aplikacja działa: `curl http://localhost:5001/api/produkty`
3. Sprawdź czy sekret jest poprawny w `.env` i WooCommerce
4. Zobacz: `WOOCOMMERCE_INTEGRATION.md` → sekcja "Rozwiązywanie problemów"

### Problem z sortowaniem?
1. Odśwież przeglądarkę (Cmd+R lub Ctrl+R)
2. Wyczyść cache (Cmd+Shift+R lub Ctrl+Shift+R)
3. Sprawdź konsolę przeglądarki (F12)

---

## 🎉 Gotowe!

Wszystkie funkcje są skonfigurowane i gotowe do użycia.

### Co dalej?
1. ✅ Przetestuj nowe funkcje UI (hover, zaznaczanie, sortowanie)
2. ✅ Sprawdź szczegóły surowców (kliknij ikonę ℹ️)
3. ✅ Skonfiguruj integrację WooCommerce (jeśli potrzebujesz)
4. ✅ Zacznij korzystać!

---

**Miłego korzystania! 🚀**

*Jeśli masz pytania, sprawdź dokumentację w plikach .md*
