# 🚀 Instrukcja Wdrożenia Aplikacji na Serwer

## Zaktualizowany kod zawiera:
- ✅ Szczegółowe logowanie webhooków
- ✅ Endpoint testowy `/api/woocommerce/test`
- ✅ Uproszczony endpoint `/api/woocommerce/webhook-simple`
- ✅ Lepszą obsługę błędów

---

## Metoda 1: Panel Hostinger (NAJŁATWIEJSZA) ⭐

### Krok 1: Zaloguj się do panelu Hostinger
1. Przejdź do: https://hpanel.hostinger.com
2. Zaloguj się

### Krok 2: Otwórz File Manager
1. Znajdź domenę `promag.flavorinthejar.com`
2. Kliknij **File Manager**
3. Przejdź do katalogu aplikacji (prawdopodobnie `public_html`)

### Krok 3: Wyślij zaktualizowany plik
1. Znajdź plik `app.py` na serwerze
2. Kliknij **Upload** (w prawym górnym rogu)
3. Wybierz plik `app.py` z Twojego komputera:
   ```
   /Users/kamilglowacki/Desktop/MagazynProdukcja/app.py
   ```
4. Potwierdź nadpisanie

### Krok 4: Zrestartuj aplikację
**Opcja A - Panel Hostinger:**
1. W panelu Hostinger znajdź **Python App** lub **Applications**
2. Znajdź aplikację `promag.flavorinthejar.com`
3. Kliknij **Restart**

**Opcja B - SSH (jeśli masz dostęp):**
```bash
# Zaloguj się przez SSH
ssh u123456789@promag.flavorinthejar.com

# Znajdź i zabij proces
pkill -f "python.*app.py"

# Uruchom ponownie
cd /home/u123456789/domains/promag.flavorinthejar.com/public_html
nohup python3 app.py > app.log 2>&1 &
```

### Krok 5: Sprawdź czy działa
Otwórz w przeglądarce:
```
https://promag.flavorinthejar.com/api/woocommerce/test
```

Powinieneś zobaczyć:
```json
{"status":"ok","message":"Test endpoint działa!"}
```

---

## Metoda 2: FTP/SFTP

### Krok 1: Pobierz klienta FTP
- **FileZilla** (darmowy): https://filezilla-project.org
- **Cyberduck** (Mac): https://cyberduck.io

### Krok 2: Połącz się z serwerem
**Dane połączenia (znajdź w panelu Hostinger):**
- Host: `ftp.flavorinthejar.com` lub IP serwera
- Użytkownik: Twój login FTP
- Hasło: Twoje hasło FTP
- Port: 21 (FTP) lub 22 (SFTP)

### Krok 3: Prześlij plik
1. Znajdź katalog aplikacji na serwerze
2. Przeciągnij plik `app.py` z lokalnego komputera
3. Potwierdź nadpisanie

### Krok 4: Zrestartuj aplikację
(Zobacz Metoda 1, Krok 4)

---

## Metoda 3: Skrypt automatyczny (dla zaawansowanych)

### Przygotowanie:
```bash
cd /Users/kamilglowacki/Desktop/MagazynProdukcja

# Nadaj uprawnienia
chmod +x deploy.sh

# Edytuj dane serwera w pliku
nano deploy.sh
```

### Wdrożenie:
```bash
./deploy.sh
```

---

## 🧪 Testowanie po wdrożeniu

### Test 1: Endpoint testowy
```bash
curl https://promag.flavorinthejar.com/api/woocommerce/test
```
Oczekiwany wynik:
```json
{"status":"ok","message":"Test endpoint działa!"}
```

### Test 2: Webhook prosty (bez weryfikacji)
```bash
curl -X POST https://promag.flavorinthejar.com/api/woocommerce/webhook-simple
```
Oczekiwany wynik:
```
OK
```

### Test 3: Webhook główny
```bash
curl -X POST https://promag.flavorinthejar.com/api/woocommerce/webhook \
  -H "Content-Type: application/json" \
  -d '{"status":"completed","id":123,"line_items":[]}'
```
Oczekiwany wynik:
```json
{"message":"Brak produktów w zamówieniu"}
```

---

## 📋 Aktualizacja webhooka w WooCommerce

Po wdrożeniu możesz użyć **uproszczonego endpointu** do testów:

### URL webhooka:
```
https://promag.flavorinthejar.com/api/woocommerce/webhook-simple
```

### Konfiguracja w WooCommerce:
1. **WooCommerce → Ustawienia → Zaawansowane → Webhooks**
2. Edytuj istniejący webhook lub utwórz nowy
3. **URL dostawy:** `https://promag.flavorinthejar.com/api/woocommerce/webhook-simple`
4. **Temat:** Order completed
5. **Sekret:** (zostaw puste dla uproszczonego endpointu)
6. Zapisz

### Test webhooka:
1. Kliknij **Dostarcz ponownie** przy webhoo ku
2. Sprawdź status - powinien być **200 OK**

---

## 🔍 Sprawdzanie logów

### Logi aplikacji Flask (SSH):
```bash
ssh u123456789@promag.flavorinthejar.com
cd /home/u123456789/domains/promag.flavorinthejar.com/public_html
tail -f app.log
```

Powinieneś zobaczyć:
```
============================================================
🔔 SIMPLE WEBHOOK - Method: POST
Headers: {...}
============================================================
```

### Logi WooCommerce:
1. **WooCommerce → Status → Logi**
2. Wybierz logi webhooków
3. Sprawdź szczegóły

---

## ❓ Rozwiązywanie problemów

### Problem: Endpoint zwraca 404
**Rozwiązanie:**
- Plik `app.py` nie został zaktualizowany na serwerze
- Wdróż ponownie plik
- Zrestartuj aplikację

### Problem: Aplikacja się nie restartuje
**Rozwiązanie:**
```bash
# SSH do serwera
ssh u123456789@promag.flavorinthejar.com

# Sprawdź czy proces działa
ps aux | grep python

# Zabij wszystkie procesy Python
pkill -9 -f python

# Uruchom ponownie
cd /sciezka/do/aplikacji
nohup python3 app.py > app.log 2>&1 &
```

### Problem: Brak dostępu SSH
**Rozwiązanie:**
- Użyj panelu Hostinger (Metoda 1)
- Lub FTP (Metoda 2)
- Skontaktuj się z supportem Hostinger o dostęp SSH

---

## ✅ Checklist wdrożenia

- [ ] Plik `app.py` wysłany na serwer
- [ ] Aplikacja zrestartowana
- [ ] Test endpoint działa (`/api/woocommerce/test`)
- [ ] Webhook prosty działa (`/api/woocommerce/webhook-simple`)
- [ ] URL webhooka zaktualizowany w WooCommerce
- [ ] Test webhooka w WooCommerce zwraca 200 OK
- [ ] Logi pokazują przychodzące requesty

---

## 🎯 Następne kroki

Po pomyślnym wdrożeniu:

1. **Przetestuj webhook** - złóż testowe zamówienie w WooCommerce
2. **Sprawdź logi** - czy webhook dociera do aplikacji
3. **Dodaj mapowania** - zmapuj produkty WooCommerce na magazynowe
4. **Przełącz na główny endpoint** - gdy wszystko działa, użyj `/api/woocommerce/webhook` z weryfikacją

---

**Powodzenia! 🚀**
