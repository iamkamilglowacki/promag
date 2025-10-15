# 📊 Szczegółowe informacje o surowcach

## ✨ Nowa funkcjonalność

Dodano **ikonę informacji** <i class="bi bi-info-circle"></i> obok wartości "Maks. produkcja" w tabeli Produkty.

Po kliknięciu ikony otwiera się okno z **szczegółowymi informacjami** o wszystkich surowcach potrzebnych do produkcji danego produktu.

---

## 🎯 Jak używać

### Krok 1: Znajdź ikonę
1. Przejdź do zakładki **Produkty**
2. W kolumnie **"Maks. produkcja (szt.)"** znajdź niebieską ikonę <i class="bi bi-info-circle"></i>
3. Ikona pojawia się obok wartości (np. "10 <i class="bi bi-info-circle"></i>")

### Krok 2: Kliknij ikonę
- Kliknij na ikonę informacji
- Otworzy się okno modalne ze szczegółami

### Krok 3: Zobacz szczegóły
Okno pokazuje tabelę ze wszystkimi surowcami:
- **Surowiec** - nazwa surowca
- **Stan dostępny** - ile masz w magazynie (g)
- **Zużycie na słoik** - ile potrzeba na jeden słoik (g)
- **Wystarczy na** - ile słoików możesz wyprodukować z tego surowca

---

## 📊 Przykład

### Tabela produktów:
```
┌─────────────┬────────┬──────────────────┐
│ Nazwa       │ Stan   │ Maks. produkcja  │
├─────────────┼────────┼──────────────────┤
│ KuraLover   │ 0 szt. │ 10 🔴 ℹ️         │
└─────────────┴────────┴──────────────────┘
```

### Po kliknięciu ikony ℹ️:

**Modal: Szczegóły surowców - KuraLover**

```
┌──────────────────────┬─────────────────┬──────────────────┬──────────────┐
│ Surowiec             │ Stan dostępny   │ Zużycie na słoik │ Wystarczy na │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Pieprz czarny 🔴     │ 80.0g           │ 8.0g             │ 10 szt.      │
│ OGRANICZA            │                 │                  │              │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Rozmaryn             │ 630.0g          │ 12.0g            │ 52 szt.      │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Tymianek             │ 550.0g          │ 10.0g            │ 55 szt.      │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Kurkuma              │ 460.0g          │ 5.0g             │ 92 szt.      │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Papryka słodka       │ 1700.0g         │ 15.0g            │ 113 szt.     │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Oregano              │ 1600.0g         │ 10.0g            │ 160 szt.     │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Imbir                │ 889.0g          │ 5.0g             │ 177 szt.     │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Papryka wędzona      │ 2000.0g         │ 10.0g            │ 200 szt.     │
├──────────────────────┼─────────────────┼──────────────────┼──────────────┤
│ Czosnek granulowany  │ 4200.0g         │ 15.0g            │ 280 szt.     │
└──────────────────────┴─────────────────┴──────────────────┴──────────────┘

ℹ️ Maksymalna produkcja: 10 szt.
   Ograniczony przez: Pieprz czarny
```

---

## 🎨 Wizualne wyróżnienia

### Ograniczający surowiec:
- **Czerwone tło** - pierwszy rząd (surowiec z najmniejszą możliwą produkcją)
- **Badge "Ogranicza"** - czerwona etykieta obok nazwy
- **Pogrubiona czcionka** - nazwa i ilość

### Pozostałe surowce:
- Białe tło
- Sortowane według możliwej produkcji (rosnąco)

---

## 💡 Co możesz z tego odczytać

### 1. **Który surowiec ogranicza produkcję**
Pierwszy rząd (czerwony) pokazuje surowiec, którego brakuje najbardziej.

**Przykład:**
```
Pieprz czarny: 80.0g dostępne, 8.0g na słoik → 10 słoików
```
Masz tylko 80g pieprzu, co wystarcza na 10 słoików. To ogranicza całą produkcję.

### 2. **Ile każdego surowca potrzebujesz na słoik**
Kolumna "Zużycie na słoik" pokazuje dokładne zapotrzebowanie.

**Przykład:**
```
Papryka słodka: 15.0g na słoik
Pieprz czarny: 8.0g na słoik
```

### 3. **Ile słoików możesz wyprodukować z każdego surowca**
Kolumna "Wystarczy na" pokazuje potencjał każdego surowca osobno.

**Przykład:**
```
Pieprz czarny: 10 szt. ← OGRANICZA
Papryka słodka: 113 szt. ← wystarczy na więcej
```

### 4. **Które surowce trzeba uzupełnić**
Surowce z małą wartością w kolumnie "Wystarczy na" wymagają uzupełnienia.

---

## 🔧 Zmiany techniczne

### Backend (app.py)

**Endpoint `/api/produkty` zwraca nowe pole:**
```python
produkt_dict['surowce_details'] = [
    {
        'nazwa': 'Pieprz czarny',
        'stan_dostepny': 80.0,
        'ilosc_na_sloik': 8.0,
        'max_sloikow': 10
    },
    # ... więcej surowców
]
```

**Dla każdego surowca oblicza:**
- `stan_dostepny` - aktualny stan w magazynie (g)
- `ilosc_na_sloik` - zużycie na jeden słoik (g)
- `max_sloikow` - ile słoików można wyprodukować

### Frontend

**JavaScript (app.js):**
- Dodano ikonę <i class="bi bi-info-circle"></i> w tabeli produktów
- Dodano funkcję `showSurowceDetails(produktId)`
- Sortowanie surowców według `max_sloikow` (rosnąco)
- Wyróżnienie ograniczającego surowca (czerwone tło + badge)

**HTML (index.html):**
- Dodano modal `surowceDetailsModal`
- Modal z tabelą szczegółów
- Alert z podsumowaniem

---

## 🎯 Przypadki użycia

### Scenariusz 1: Planowanie zakupów
1. Kliknij ikonę ℹ️ przy produkcie
2. Zobacz który surowiec ogranicza (czerwony rząd)
3. Sprawdź ile go potrzebujesz
4. Zamów odpowiednią ilość

**Przykład:**
```
Pieprz czarny: 80.0g dostępne, 8.0g na słoik → 10 słoików

Chcę wyprodukować 50 słoików:
50 słoików × 8.0g = 400g potrzebne
80g dostępne - 400g potrzebne = -320g brakuje

Zamów: 320g pieprzu czarnego (lub więcej z zapasem)
```

### Scenariusz 2: Optymalizacja produkcji
1. Zobacz szczegóły dla kilku produktów
2. Porównaj które produkty możesz wyprodukować w większych ilościach
3. Zaplanuj produkcję produktów, dla których masz wystarczająco surowców

### Scenariusz 3: Analiza receptury
1. Sprawdź zużycie każdego surowca na słoik
2. Zidentyfikuj najdroższe/najbardziej zużywane surowce
3. Rozważ modyfikację receptury

---

## 📁 Zmodyfikowane pliki

1. **app.py** - endpoint `/api/produkty` zwraca `surowce_details`
2. **static/js/app.js** - dodano funkcję `showSurowceDetails()` i ikonę
3. **templates/index.html** - dodano modal `surowceDetailsModal`

---

## 🚀 Korzyści

### Przed:
- ❌ Tylko informacja "Ogranicza: Pieprz czarny"
- ❌ Nie wiadomo ile brakuje
- ❌ Nie wiadomo ile potrzeba innych surowców

### Teraz:
- ✅ Szczegółowa tabela wszystkich surowców
- ✅ Dokładne ilości dostępne i potrzebne
- ✅ Wizualne wyróżnienie ograniczającego surowca
- ✅ Łatwe planowanie zakupów
- ✅ Pełna transparentność

---

## 🎨 Przykład wizualny

```
Tabela Produkty:
┌─────────────┬──────────────────┐
│ Nazwa       │ Maks. produkcja  │
├─────────────┼──────────────────┤
│ KuraLover   │ 10 🔴 ℹ️ ← KLIKNIJ
└─────────────┴──────────────────┘

                    ↓

Modal:
╔═══════════════════════════════════════════════════╗
║ Szczegóły surowców - KuraLover                    ║
╠═══════════════════════════════════════════════════╣
║ ┌──────────────┬─────────┬─────────┬───────────┐ ║
║ │ Surowiec     │ Dostępne│ Na słoik│ Wystarczy │ ║
║ ├──────────────┼─────────┼─────────┼───────────┤ ║
║ │ Pieprz 🔴    │ 80.0g   │ 8.0g    │ 10 szt.   │ ║
║ │ OGRANICZA    │         │         │           │ ║
║ ├──────────────┼─────────┼─────────┼───────────┤ ║
║ │ Rozmaryn     │ 630.0g  │ 12.0g   │ 52 szt.   │ ║
║ │ ...          │ ...     │ ...     │ ...       │ ║
║ └──────────────┴─────────┴─────────┴───────────┘ ║
║                                                   ║
║ ℹ️ Maksymalna produkcja: 10 szt.                 ║
║    Ograniczony przez: Pieprz czarny              ║
╚═══════════════════════════════════════════════════╝
```

---

**Miłego korzystania! 🎉**
