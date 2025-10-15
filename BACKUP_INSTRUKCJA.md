# 💾 System Backupu Bazy Danych

## ✅ **AUTOMATYCZNY BACKUP**

### **Jak to działa:**
- 🕐 **Backup codziennie o północy** (00:00-01:00)
- 🔄 **Zintegrowany z watchdogiem** - działa automatycznie
- 🗑️ **Automatyczne czyszczenie** - usuwa backupy starsze niż 30 dni
- 📊 **Logowanie** - wszystkie operacje są zapisywane

### **Lokalizacja:**
```
~/promag/backups/magazyn_backup_YYYYMMDD_HHMMSS.db
```

### **Logi:**
```
~/promag/backup.log
```

---

## 📋 **KOMENDY**

### **1. Ręczny backup (w dowolnym momencie):**
```bash
./manual_backup.sh
```

### **2. Sprawdź backupy:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "ls -lh ~/promag/backups/"
```

### **3. Sprawdź logi backupu:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "tail -20 ~/promag/backup.log"
```

### **4. Przywróć backup:**
```bash
./restore_backup.sh
```
*Skrypt pokaże listę dostępnych backupów i pozwoli wybrać który przywrócić*

### **5. Pobierz backup lokalnie:**
```bash
scp -P 65002 u923457281@46.17.175.219:~/promag/backups/magazyn_backup_YYYYMMDD_HHMMSS.db ./
```

---

## 🔍 **MONITORING**

### **Sprawdź czy watchdog działa (odpowiada za backup):**
```bash
ssh -p 65002 u923457281@46.17.175.219 "ps aux | grep supervisor_watchdog | grep -v grep"
```

### **Sprawdź ostatni backup:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "ls -lht ~/promag/backups/ | head -3"
```

### **Sprawdź liczbę backupów:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "ls -1 ~/promag/backups/ | wc -l"
```

---

## 📊 **STATYSTYKI**

### **Rozmiar wszystkich backupów:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "du -sh ~/promag/backups/"
```

### **Najstarszy backup:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "ls -lt ~/promag/backups/ | tail -2"
```

---

## 🛠️ **KONFIGURACJA**

### **Zmiana czasu backupu:**
Edytuj plik `~/promag/supervisor_watchdog.sh` na serwerze:
```bash
# Zmień linię:
if [ "$CURRENT_HOUR" = "00" ]; then
# Na przykład dla 3:00 rano:
if [ "$CURRENT_HOUR" = "03" ]; then
```

### **Zmiana retencji (ile dni przechowywać):**
Edytuj plik `~/promag/backup_database.sh` na serwerze:
```bash
# Zmień linię:
find "$BACKUP_DIR" -name "magazyn_backup_*.db" -mtime +30 -delete
# Na przykład dla 60 dni:
find "$BACKUP_DIR" -name "magazyn_backup_*.db" -mtime +60 -delete
```

---

## ⚠️ **WAŻNE**

### **Backup działa tylko gdy watchdog jest aktywny!**

Sprawdź status watchdoga:
```bash
ps aux | grep supervisor_watchdog | grep -v grep
```

Jeśli nie działa, uruchom:
```bash
ssh -p 65002 u923457281@46.17.175.219 "nohup bash -c 'while true; do ~/promag/supervisor_watchdog.sh; sleep 60; done' > /dev/null 2>&1 &"
```

### **Po restarcie serwera:**
```bash
./start_all.sh  # Uruchamia Supervisor + aplikację
# Następnie uruchom watchdog (który robi backupy)
ssh -p 65002 u923457281@46.17.175.219 "nohup bash -c 'while true; do ~/promag/supervisor_watchdog.sh; sleep 60; done' > /dev/null 2>&1 &"
```

---

## 🔄 **SCENARIUSZE UŻYCIA**

### **Scenariusz 1: Codzienny backup (automatyczny)**
```
00:00 → Watchdog wykrywa północ
     → Wykonuje backup
     → Zapisuje log
     → Usuwa stare backupy (>30 dni)
```

### **Scenariusz 2: Backup przed ważną zmianą**
```bash
# Przed zmianą:
./manual_backup.sh

# Wykonaj zmiany w aplikacji...

# Jeśli coś poszło nie tak:
./restore_backup.sh
```

### **Scenariusz 3: Przywracanie po awarii**
```bash
# 1. Sprawdź dostępne backupy
ssh -p 65002 u923457281@46.17.175.219 "ls -lh ~/promag/backups/"

# 2. Przywróć wybrany backup
./restore_backup.sh

# 3. Aplikacja zostanie automatycznie zrestartowana
```

---

## 📈 **PRZYKŁADOWY LOG**

```
[2025-10-15 00:00:15] 🕐 Północ - wykonuję backup...
[2025-10-15 00:00:15] ✅ Backup utworzony: magazyn_backup_20251015_000015.db
[2025-10-15 00:00:15] 🗑️  Usunięto 2 starych backupów
[2025-10-15 00:00:15] 📊 Backupów: 28 | Rozmiar: 68K
```

---

## 🎯 **BEST PRACTICES**

1. ✅ **Regularnie sprawdzaj logi** - `tail ~/promag/backup.log`
2. ✅ **Pobieraj backupy lokalnie** - dodatkowa kopia poza serwerem
3. ✅ **Testuj przywracanie** - raz na jakiś czas sprawdź czy backup działa
4. ✅ **Monitoruj miejsce na dysku** - `df -h`
5. ✅ **Przed dużymi zmianami** - zrób ręczny backup

---

## 🚨 **TROUBLESHOOTING**

### **Problem: Backup się nie wykonuje**
```bash
# Sprawdź watchdog
ps aux | grep supervisor_watchdog

# Sprawdź logi
tail -50 ~/promag/backup.log

# Uruchom ręcznie aby zobaczyć błędy
ssh -p 65002 u923457281@46.17.175.219"~/promag/backup_database.sh"
```

### **Problem: Brak miejsca na dysku**
```bash
# Sprawdź miejsce
ssh -p 65002 u923457281@46.17.175.219 "df -h"

# Usuń stare backupy ręcznie
ssh -p 65002 u923457281@46.17.175.219 "rm ~/promag/backups/magazyn_backup_2025*.db"
```

### **Problem: Backup jest pusty (0 KB)**
```bash
# Sprawdź czy baza danych istnieje
ssh -p 65002 u923457281@46.17.175.219 "ls -lh ~/promag/magazyn.db"

# Sprawdź uprawnienia
ssh -p 65002 u923457281@46.17.175.219 "ls -la ~/promag/"
```

---

## ✅ **PODSUMOWANIE**

| Element | Status | Opis |
|---------|--------|------|
| **Automatyczny backup** | ✅ Aktywny | Codziennie o 00:00 |
| **Retencja** | ✅ 30 dni | Automatyczne czyszczenie |
| **Lokalizacja** | ✅ ~/promag/backups/ | Bezpieczne miejsce |
| **Logowanie** | ✅ ~/promag/backup.log | Pełna historia |
| **Ręczny backup** | ✅ ./manual_backup.sh | W każdej chwili |
| **Przywracanie** | ✅ ./restore_backup.sh | Łatwe i bezpieczne |

**Twoje dane są bezpieczne!** 🛡️
