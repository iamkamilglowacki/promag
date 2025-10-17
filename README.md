# System Magazynowy - Mieszanki Przypraw

Prosty system do obsługi magazynu surowców i produkcji mieszanek przypraw.

🚀 **Automatyczne wdrożenia przez GitHub Webhooks!**

## Funkcjonalności

- ✅ **Zarządzanie surowcami** - dodawanie, edycja, kontrola stanów
- ✅ **Produkty** - zarządzanie gotowymi mieszankami ze stanem magazynowym
- ✅ **Receptury** - definiowanie składników mieszanek (na 100g produktu)
- ✅ **Dostawy** - rejestracja dostaw z automatyczną aktualizacją stanów
- ✅ **Produkcja** - rejestracja produkcji z automatycznym odejmowaniem surowców i zwiększaniem stanu produktów
- ✅ **Cykle produkcyjne** - planowanie i wykonywanie produkcji z walidacją zasobów
- ✅ **Potencjał produkcyjny** - automatyczne obliczanie maksymalnej produkcji
- ✅ **Dashboard** - przegląd kluczowych wskaźników
- ✅ **Integracja WooCommerce** - automatyczna aktualizacja stanów po zakupach
- ✅ **Dostęp wielourządzeniowy** - działanie w sieci lokalnej

## Instalacja i uruchomienie

### Wymagania
- Python 3.7+
- pip

### Kroki instalacji

#### Opcja 1: Automatyczne uruchomienie (zalecane)
```bash
./start.sh
```

#### Opcja 2: Ręczne uruchomienie
1. **Stwórz środowisko wirtualne:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Zainstaluj zależności:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Uruchom aplikację:**
   ```bash
   python app.py
   ```

4. **Otwórz w przeglądarce:**
   - Lokalnie: http://localhost:5001
   - Z innych urządzeń w sieci: http://[IP_KOMPUTERA]:5001

### Znajdowanie adresu IP

**Na macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Na Windows:**
```cmd
ipconfig
```

## Użytkowanie

### Dashboard
- Przegląd kluczowych statystyk
- Potencjał produkcyjny
- Ostatnie działania

### Surowce
- Lista wszystkich surowców z aktualnym stanem
- Dodawanie nowych surowców
- Kontrola stanów magazynowych

### Produkty
- Lista gotowych mieszanek ze stanem magazynowym w sztukach (słoikach)
- Definiowanie gramatury słoika (ile gramów mieści jeden słoik)
- **AUTOMATYCZNE ODEJMOWANIE SUROWCÓW** przy dodawaniu/zwiększaniu stanu produktów
- Sprawdzanie dostępności surowców przed dodaniem produktu
- Edycja stanu magazynowego i gramatury produktów
- Automatyczne przeliczanie łącznej wagi w gramach

### Receptury
- Definiowanie składników mieszanek (na 100g produktu)
- Zarządzanie proporcjami składników
- Łatwe dodawanie i usuwanie składników z receptur
- **KLUCZOWE:** Receptury są używane do automatycznego odejmowania surowców przy dodawaniu produktów

### Dostawy
- Rejestracja nowych dostaw
- Automatyczna aktualizacja stanów magazynowych
- Historia wszystkich dostaw

### Produkcja
- Rejestracja produkcji mieszanek w sztukach (słoikach)
- Automatyczne przeliczanie potrzebnych surowców na podstawie gramatury słoika
- Automatyczne odejmowanie surowców według receptury
- Automatyczne zwiększanie stanu magazynowego produktów w sztukach
- Kontrola dostępności surowców przed produkcją

### Potencjał Produkcyjny
- Automatyczne obliczanie maksymalnej produkcji każdej mieszanki w sztukach
- Wyświetlanie gramatury słoika dla każdego produktu
- Identyfikacja ograniczających surowców
- Pomoc w planowaniu produkcji

## Integracja WooCommerce

System może automatycznie aktualizować stany magazynowe po zakupach w sklepie WooCommerce.

**Szczegółowa instrukcja:** Zobacz plik `WOOCOMMERCE_INTEGRATION.md`

**Krótko:**
1. Skonfiguruj webhook w WooCommerce
2. Dodaj sekret do pliku `.env`
3. Zmapuj produkty WooCommerce z produktami magazynowymi
4. System automatycznie odejmie produkty po każdym zakupie

## Struktura bazy danych

Aplikacja używa SQLite z następującymi tabelami:
- `surowiec` - surowce i ich stany magazynowe
- `produkt` - produkty (mieszanki) z ich stanami magazynowymi w sztukach i gramaturą słoika
- `receptura` - składniki produktów (receptury)
- `dostawa` - historia dostaw surowców
- `produkcja` - historia produkcji mieszanek
- `cykl_produkcyjny` - planowane i wykonane cykle produkcyjne
- `cykl_pozycja` - pozycje w cyklach produkcyjnych
- `woo_commerce_mapowanie` - mapowanie produktów WooCommerce na produkty magazynowe
- `historia_surowcow` - historia operacji na surowcach
- `historia_produktow` - historia operacji na produktach

## Przykładowe dane

Aplikacja automatycznie tworzy przykładowe dane przy pierwszym uruchomieniu:

**Surowce:**
- Papryka słodka (1000g)
- Sól (2000g)
- Czosnek granulowany (500g)
- Pieprz czarny (300g)
- Oregano (200g)

**Produkty:**
- KuraLover - mieszanka do kurczaka
- Ziemniak Rulezzz - mieszanka do ziemniaków

## Dostęp z tableta/telefonu

1. Upewnij się, że wszystkie urządzenia są w tej samej sieci Wi-Fi
2. Znajdź adres IP komputera z aplikacją
3. Na tablecie/telefonie otwórz przeglądarkę
4. Wpisz adres: http://[IP_KOMPUTERA]:5001

## Rozwiązywanie problemów

### Aplikacja nie uruchamia się
- Sprawdź czy Python jest zainstalowany
- Upewnij się, że wszystkie zależności są zainstalowane: `pip install -r requirements.txt`

### Nie można połączyć się z innych urządzeń
- Sprawdź czy firewall nie blokuje portu 5001
- Upewnij się, że wszystkie urządzenia są w tej samej sieci
- Sprawdź adres IP komputera

### Błędy bazy danych
- Usuń plik `magazyn.db` i uruchom aplikację ponownie
- Aplikacja automatycznie utworzy nową bazę z przykładowymi danymi

## Backup danych

Baza danych znajduje się w pliku `magazyn.db`. Aby zrobić kopię zapasową:
```bash
cp magazyn.db magazyn_backup_$(date +%Y%m%d).db
```

## Rozwój aplikacji

Aplikacja jest napisana w Flask i może być łatwo rozszerzona o dodatkowe funkcjonalności:
- Raporty i wykresy
- Export do Excel
- Powiadomienia o niskich stanach
- Zarządzanie użytkownikami
- ✅ **Integracja WooCommerce** - już zaimplementowana!
- Integracja z innymi platformami e-commerce (Shopify, PrestaShop, etc.)

## Pliki projektu

- `app.py` - główna aplikacja Flask z API
- `templates/` - szablony HTML
- `static/` - pliki CSS, JS, obrazy
- `magazyn.db` - baza danych SQLite
- `requirements.txt` - zależności Python
- `start.sh` - skrypt uruchamiający
- `README.md` - ten plik
- `WOOCOMMERCE_INTEGRATION.md` - instrukcja integracji WooCommerce
- `.env.example` - przykładowa konfiguracja
