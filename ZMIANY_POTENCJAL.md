# 🔄 Zmiany: Usunięcie zakładki "Potencjał Produkcyjny"

## ✅ Co zostało zrobione

### 1. **Usunięto zakładkę "Potencjał Produkcyjny"**
- ❌ Usunięto link z menu bocznego
- ❌ Usunięto całą sekcję HTML z tabelą potencjału
- ❌ Usunięto sekcję z dashboardu

### 2. **Dodano kolumnę "Maks. produkcja" do tabeli Produkty**
- ✅ Nowa kolumna pokazuje maksymalną możliwą produkcję (w sztukach)
- ✅ Kolumna jest sortowalna (kliknij na nagłówek)
- ✅ Tooltip pokazuje ograniczający surowiec
- ✅ Kolorowanie jak stan magazynowy (czerwony/pomarańczowy/zielony)

---

## 🎯 Nowa funkcjonalność

### Kolumna "Maks. produkcja (szt.)"

**Lokalizacja:** Zakładka **Produkty** → tabela produktów

**Co pokazuje:**
- Maksymalną liczbę słoików, którą można wyprodukować
- Obliczane na podstawie dostępnych surowców i receptury
- Uwzględnia ograniczający surowiec (ten, którego jest najmniej)

**Przykład:**
```
Produkt: KuraLover
Stan: 0 szt.
Maks. produkcja: 10 szt.
Tooltip: "Ogranicza: Pieprz czarny"
```

Oznacza to, że możesz wyprodukować maksymalnie 10 słoików KuraLover, ponieważ masz wystarczająco dużo pieprzu czarnego (który jest ograniczającym surowcem).

---

## 📊 Sortowanie

Kolumna "Maks. produkcja" jest **sortowalna**:

1. **Kliknij na nagłówek** "Maks. produkcja (szt.)"
2. **Rosnąco** ↑ - produkty z najmniejszą możliwą produkcją na górze
3. **Malejąco** ↓ - produkty z największą możliwą produkcją na górze

**Użycie:**
- Sortuj rosnąco aby zobaczyć które produkty mają najmniejszy potencjał produkcyjny
- Pomaga zidentyfikować produkty, dla których brakuje surowców

---

## 🎨 Kolorowanie

Kolumna "Maks. produkcja" używa tych samych kolorów co stan magazynowy:

- 🔴 **Czerwony** - niska produkcja (0-5 szt.)
- 🟠 **Pomarańczowy** - średnia produkcja (6-10 szt.)
- 🟢 **Zielony** - wysoka produkcja (11+ szt.)

---

## 🔧 Zmiany techniczne

### Backend (app.py)

**Zmodyfikowano endpoint `/api/produkty`:**
```python
@app.route('/api/produkty', methods=['GET'])
def get_produkty():
    # Dla każdego produktu oblicza:
    # - max_produkcja (int) - maksymalna liczba słoików
    # - ograniczajacy_surowiec (str) - nazwa surowca
```

**Dodane pola w odpowiedzi API:**
- `max_produkcja` - liczba całkowita (szt.)
- `ograniczajacy_surowiec` - string (nazwa surowca)

### Frontend

**HTML (templates/index.html):**
- ❌ Usunięto link "Potencjał Produkcyjny" z menu
- ❌ Usunięto sekcję `<div id="potencjal">`
- ❌ Usunięto kartę potencjału z dashboardu
- ✅ Dodano kolumnę `<th id="produktyMaxProdHeader">` do tabeli produktów

**JavaScript (static/js/app.js):**
- ❌ Usunięto funkcję `loadPotencjal()`
- ❌ Usunięto funkcję `renderPotencjalTable()`
- ❌ Usunięto funkcję `updatePotencjalDashboard()`
- ❌ Usunięto zmienną globalną `potencjal`
- ❌ Usunięto case 'potencjal' z switch
- ✅ Zaktualizowano `renderProduktyTable()` - dodano kolumnę max_produkcja

**JavaScript (static/js/table-utils.js):**
- ✅ Dodano sortowanie dla kolumny "Maks. produkcja"

---

## 📁 Zmodyfikowane pliki

1. **app.py** - endpoint `/api/produkty` oblicza max_produkcja
2. **templates/index.html** - usunięto zakładkę, dodano kolumnę
3. **static/js/app.js** - usunięto funkcje potencjału, zaktualizowano renderowanie
4. **static/js/table-utils.js** - dodano sortowanie dla nowej kolumny

---

## 🚀 Korzyści

### Przed:
- ❌ Dwie osobne zakładki (Produkty i Potencjał)
- ❌ Trzeba przełączać się między zakładkami
- ❌ Informacja o potencjale oddzielona od stanu

### Teraz:
- ✅ Wszystko w jednym miejscu (zakładka Produkty)
- ✅ Widać stan i potencjał obok siebie
- ✅ Łatwiejsze porównanie
- ✅ Mniej kliknięć
- ✅ Bardziej intuicyjne

---

## 💡 Przykład użycia

### Scenariusz: Planowanie produkcji

1. Przejdź do zakładki **Produkty**
2. Kliknij na **"Maks. produkcja (szt.)"** aby posortować
3. Zobacz które produkty mają najmniejszy potencjał
4. Najedź myszką na wartość - zobaczysz ograniczający surowiec
5. Zamów więcej tego surowca lub zaplanuj produkcję innych produktów

**Przykład:**
```
┌─────────────────┬────────┬──────────────────┬─────────────────────┐
│ Nazwa           │ Stan   │ Maks. produkcja  │ Tooltip             │
├─────────────────┼────────┼──────────────────┼─────────────────────┤
│ KuraLover       │ 0 szt. │ 10 szt. 🟠       │ Ogranicza: Pieprz   │
│ Ziemniak Rulezzz│ 4 szt. │ 25 szt. 🟢       │ Ogranicza: Czosnek  │
│ Italiana        │ 6 szt. │ 5 szt. 🔴        │ Ogranicza: Bazylia  │
└─────────────────┴────────┴──────────────────┴─────────────────────┘
```

Z tej tabeli widać, że:
- **Italiana** ma najmniejszy potencjał (5 szt.) - brakuje bazylii
- **KuraLover** można wyprodukować 10 szt. - brakuje pieprzu
- **Ziemniak Rulezzz** ma największy potencjał (25 szt.)

---

## 🎯 Podsumowanie

✅ Zakładka "Potencjał Produkcyjny" została usunięta  
✅ Informacja o maksymalnej produkcji jest teraz w tabeli Produkty  
✅ Kolumna jest sortowalna i kolorowana  
✅ Tooltip pokazuje ograniczający surowiec  
✅ Wszystko w jednym miejscu - łatwiejsze w użyciu  

---

**Miłego korzystania! 🎉**
