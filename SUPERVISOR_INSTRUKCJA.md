# 🛡️ Supervisor - Instrukcja Obsługi

## ✅ **Status: ZAINSTALOWANY I DZIAŁA!**

Supervisor został pomyślnie zainstalowany i zarządza aplikacją Flask.

---

## 🎯 **Co robi Supervisor:**

- ✅ **Automatycznie restartuje** aplikację gdy się zatrzyma
- ✅ **Monitoruje** proces 24/7
- ✅ **Loguje** wszystkie zdarzenia
- ✅ **Zarządza** uruchamianiem i zatrzymywaniem

---

## 📋 **Podstawowe komendy:**

### **1. Sprawdź status:**
```bash
./supervisor_status.sh
```

LUB bezpośrednio na serwerze:
```bash
ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status"
```

### **2. Restart aplikacji:**
```bash
./supervisor_restart.sh
```

LUB bezpośrednio:
```bash
ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf restart promag"
```

### **3. Zobacz logi na żywo:**
```bash
./supervisor_logs.sh
```

### **4. Zatrzymaj aplikację:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf stop promag"
```

### **5. Uruchom aplikację:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf start promag"
```

---

## 📊 **Statusy aplikacji:**

| Status | Znaczenie |
|--------|-----------|
| **RUNNING** | ✅ Aplikacja działa prawidłowo |
| **STARTING** | ⏳ Aplikacja się uruchamia |
| **STOPPED** | 🛑 Aplikacja zatrzymana (ręcznie) |
| **FATAL** | ❌ Błąd krytyczny - nie można uruchomić |
| **BACKOFF** | ⚠️ Próba restartu po awarii |

---

## 📁 **Lokalizacja plików:**

### **Na serwerze:**

```
~/supervisor/
├── supervisord.conf          # Konfiguracja Supervisor
├── supervisord.pid           # PID procesu Supervisor
├── supervisor.sock           # Socket do komunikacji
└── logs/
    ├── supervisord.log       # Logi Supervisor
    ├── promag.out.log        # Logi aplikacji (stdout)
    └── promag.err.log        # Błędy aplikacji (stderr)
```

### **Lokalnie:**

```
supervisor_status.sh          # Sprawdź status
supervisor_restart.sh         # Restart aplikacji
supervisor_logs.sh            # Zobacz logi na żywo
```

---

## 🧪 **Test automatycznego restartu:**

Supervisor **automatycznie restartuje** aplikację gdy:
- Proces się zatrzyma
- Aplikacja crashuje
- Zabije się proces (kill)

**Przetestowane:** ✅ Działa!

```
💀 Zabito proces → ⏳ Czekanie 3s → ✅ Automatyczny restart
```

---

## ⚠️ **Po restarcie serwera:**

Supervisor **NIE uruchomi się automatycznie** po restarcie serwera (Hostinger nie wspiera crontab).

### **Ręczne uruchomienie po restarcie:**

```bash
ssh -p 65002 u923457281@46.17.175.219 'bash -s' << 'EOF'
# Uruchom Supervisor
~/.local/bin/supervisord -c ~/supervisor/supervisord.conf

# Sprawdź status
sleep 3
~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf status
EOF
```

LUB użyj skryptu:
```bash
./restart_app.sh
```

---

## 🔧 **Konfiguracja:**

Plik konfiguracyjny: `~/supervisor/supervisord.conf`

### **Główne ustawienia:**

```ini
[program:promag]
command=/usr/bin/python3 /home/u923457281/promag/app.py
directory=/home/u923457281/promag
autostart=true          # Uruchom automatycznie
autorestart=true        # Restartuj przy awarii
startretries=3          # Maksymalnie 3 próby restartu
```

### **Zmiana konfiguracji:**

1. Edytuj plik na serwerze
2. Przeładuj konfigurację:
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf reread"
   ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf update"
   ```

---

## 📊 **Monitoring:**

### **Sprawdź czy Supervisor działa:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "ps aux | grep supervisord | grep -v grep"
```

### **Sprawdź logi Supervisor:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "tail -50 ~/supervisor/logs/supervisord.log"
```

### **Sprawdź błędy aplikacji:**
```bash
ssh -p 65002 u923457281@46.17.175.219 "tail -50 ~/supervisor/logs/promag.err.log"
```

---

## 🚨 **Rozwiązywanie problemów:**

### **Problem: Aplikacja nie startuje (FATAL)**

1. Sprawdź błędy:
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "tail -50 ~/supervisor/logs/promag.err.log"
   ```

2. Sprawdź czy Python działa:
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "cd ~/promag && python3 app.py"
   ```

3. Sprawdź uprawnienia:
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "ls -la ~/promag/app.py"
   ```

### **Problem: Supervisor nie działa**

1. Uruchom ponownie:
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "~/.local/bin/supervisord -c ~/supervisor/supervisord.conf"
   ```

2. Sprawdź logi:
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "tail -50 ~/supervisor/logs/supervisord.log"
   ```

### **Problem: Aplikacja ciągle się restartuje (BACKOFF)**

To oznacza że aplikacja crashuje zaraz po starcie.

1. Sprawdź błędy w logach
2. Przetestuj aplikację ręcznie
3. Sprawdź czy wszystkie zależności są zainstalowane

---

## ✅ **Podsumowanie:**

| Co | Status |
|----|--------|
| Supervisor zainstalowany | ✅ |
| Aplikacja zarządzana przez Supervisor | ✅ |
| Automatyczny restart | ✅ Działa |
| Logowanie | ✅ Skonfigurowane |
| Skrypty pomocnicze | ✅ Gotowe |

---

## 🎯 **Następne kroki:**

1. ✅ **Monitoruj przez kilka dni** - sprawdzaj czy aplikacja działa stabilnie
2. ✅ **Sprawdzaj logi** regularnie: `./supervisor_logs.sh`
3. ⚠️ **Po restarcie serwera** - uruchom Supervisor ręcznie
4. 💡 **Opcjonalnie** - dodaj Watchdog który uruchomi Supervisor po restarcie

---

## 📞 **Quick Reference:**

```bash
# Status
./supervisor_status.sh

# Restart
./supervisor_restart.sh

# Logi na żywo
./supervisor_logs.sh

# Sprawdź czy działa
curl https://promag.flavorinthejar.com/
```

**Aplikacja jest teraz stabilna i będzie automatycznie restartowana przy awarii!** 🎉
