# 🎨 Nowe funkcje interfejsu

## ✨ Dodane funkcjonalności

### 1. **Efekty Hover** 🖱️

#### Rzędy tabel
- **Zmiana koloru** - rząd staje się jaśniejszy przy najechaniu myszką
- **Delikatne powiększenie** - efekt scale(1.01)
- **Subtelny cień** - dodaje głębi
- **Płynna animacja** - transition 0.2s
- **Kursor pointer** - wskazuje że można kliknąć

#### Karty (Cards)
- **Podniesienie** - karta unosi się o 2px
- **Większy cień** - efekt 3D
- **Płynna animacja**

#### Przyciski
- **Podniesienie** - przycisk unosi się o 1px
- **Cień** - dodaje głębi
- **Efekt wciśnięcia** - przy kliknięciu

#### Menu boczne
- **Zmiana koloru** - przy hover
- **Przesunięcie w prawo** - 5px
- **Płynna animacja**

---

### 2. **Zaznaczanie rzędów** ✅

#### Jak używać:
1. **Kliknij na rząd** w tabeli (Surowce lub Produkty)
2. Rząd zmieni kolor na **niebieski**
3. Po lewej stronie pojawi się **niebieska linia**
4. **Kliknij ponownie** aby odznaczyć

#### Funkcje:
- ✅ Zaznaczanie pojedynczych rzędów
- ✅ Zaznaczanie wielu rzędów jednocześnie
- ✅ Wizualne wyróżnienie (niebieski kolor)
- ✅ Lewa niebieska linia (border-left)
- ✅ Pogrubiona czcionka dla zaznaczonych

#### Kolory:
- **Normalny:** tło białe/szare
- **Hover:** jasny szary (#e9ecef)
- **Zaznaczony:** jasny niebieski (#cfe2ff)
- **Zaznaczony + Hover:** ciemniejszy niebieski (#b6d4fe)

---

### 3. **Sortowanie tabel** 🔢

#### Jak używać:
1. **Kliknij na nagłówek** kolumny "Stan (g)" lub "Stan (szt.)"
2. Tabela posortuje się **rosnąco** (od najmniejszej do największej)
3. **Kliknij ponownie** - sortowanie **malejąco** (od największej do najmniejszej)
4. **Kliknij trzeci raz** - powrót do kolejności domyślnej

#### Wskaźniki:
- **⇅** - kolumna jest sortowalna (szary)
- **↑** - sortowanie rosnące (niebieski)
- **↓** - sortowanie malejące (niebieski)

#### Sortowalne kolumny:
- **Surowce:** Stan (g) - sortowanie numeryczne
- **Produkty:** Stan (szt.) - sortowanie numeryczne

#### Funkcje:
- ✅ Sortowanie numeryczne (uwzględnia liczby)
- ✅ Wizualne wskaźniki kierunku
- ✅ Hover na nagłówku (zmiana koloru)
- ✅ Tooltip "Kliknij aby posortować"

---

## 🎯 Przykłady użycia

### Scenariusz 1: Znajdź produkty z najmniejszym stanem
1. Przejdź do zakładki **Produkty**
2. Kliknij na nagłówek **"Stan (szt.)"**
3. Produkty posortują się od najmniejszego stanu
4. Pierwsze produkty to te, które trzeba uzupełnić

### Scenariusz 2: Zaznacz produkty do produkcji
1. Przejdź do zakładki **Produkty**
2. Posortuj po stanie (rosnąco)
3. Kliknij na produkty z niskim stanem
4. Zaznaczone produkty są wyróżnione na niebiesko
5. Możesz teraz zaplanować produkcję tych produktów

### Scenariusz 3: Sprawdź surowce z największym stanem
1. Przejdź do zakładki **Surowce**
2. Kliknij na nagłówek **"Stan (g)"**
3. Kliknij ponownie (sortowanie malejące)
4. Pierwsze surowce to te z największym stanem

---

## 🎨 Style CSS

### Zaznaczony rząd:
```css
.table tbody tr.selected {
    background-color: #cfe2ff !important;
    border-left: 4px solid #0d6efd;
    font-weight: 500;
}
```

### Sortowalna kolumna:
```css
.table th.sortable {
    cursor: pointer;
    user-select: none;
    position: relative;
    padding-right: 25px;
}
```

### Wskaźnik sortowania:
```css
.table th.sortable.asc::after {
    content: '↑';
    opacity: 1;
    color: #0d6efd;
}
```

---

## 📝 Pliki zmodyfikowane

### 1. `static/css/style.css`
- Dodano style hover dla rzędów tabel
- Dodano style dla zaznaczonych rzędów
- Dodano style dla sortowalnych nagłówków
- Dodano style hover dla kart i przycisków

### 2. `static/js/table-utils.js` (NOWY)
- Funkcje zaznaczania rzędów
- Funkcje sortowania kolumn
- Automatyczna inicjalizacja

### 3. `templates/index.html`
- Dodano ID do nagłówków tabel
- Dodano klasę "sortable"
- Dodano tooltip
- Dołączono nowy skrypt

---

## 🚀 Korzyści

### UX (User Experience):
- ✅ Lepsze wizualne feedback
- ✅ Łatwiejsze znajdowanie produktów
- ✅ Szybsze podejmowanie decyzji
- ✅ Profesjonalny wygląd

### Funkcjonalność:
- ✅ Szybkie sortowanie danych
- ✅ Zaznaczanie wielu elementów
- ✅ Intuicyjna obsługa
- ✅ Responsywność

### Wydajność:
- ✅ Płynne animacje (CSS transitions)
- ✅ Delegacja zdarzeń (event delegation)
- ✅ Minimalne obciążenie CPU

---

## 🐛 Znane ograniczenia

1. **Sortowanie działa tylko na załadowanych danych**
   - Jeśli dane są ładowane dynamicznie, sortowanie może się zresetować

2. **Zaznaczenie ginie po odświeżeniu**
   - Zaznaczenia nie są zapisywane w localStorage

3. **Brak multi-select z Shift/Ctrl**
   - Obecnie tylko pojedyncze kliknięcia

---

## 🔮 Przyszłe ulepszenia

- [ ] Zapisywanie zaznaczonych rzędów w localStorage
- [ ] Multi-select z Shift (zaznacz zakres)
- [ ] Multi-select z Ctrl/Cmd (zaznacz wiele)
- [ ] Sortowanie po wielu kolumnach
- [ ] Filtrowanie tabel
- [ ] Export zaznaczonych rzędów
- [ ] Akcje grupowe na zaznaczonych rzędach

---

## 📞 Wsparcie

Jeśli masz problemy:
1. Odśwież przeglądarkę (Cmd+R / Ctrl+R)
2. Wyczyść cache (Cmd+Shift+R / Ctrl+Shift+R)
3. Sprawdź konsolę przeglądarki (F12)

---

**Miłego korzystania! 🎉**
