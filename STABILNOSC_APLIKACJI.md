# 🛡️ Stabilność Aplikacji - Rozwiązania

## ⚠️ **Problem:**
Aplikacja Flask uruchamiana przez `nohup` zatrzymuje się po restarcie serwera lub awarii.

---

## ✅ **Rozwiązania (od najlepszego):**

### **1. Watchdog Script (NAJŁATWIEJSZE - POLECAM)**

Prosty skrypt który sprawdza co minutę czy aplikacja działa i restartuje ją automatycznie.

#### **Instalacja:**
```bash
chmod +x setup_watchdog.sh
./setup_watchdog.sh
```

#### **Zalety:**
- ✅ Bardzo proste
- ✅ Nie wymaga dodatkowych uprawnień
- ✅ Działa na każdym hostingu
- ✅ Automatyczny restart przy awarii
- ✅ Sprawdza czy aplikacja odpowiada (nie tylko czy proces działa)

#### **Wady:**
- ⚠️ Opóźnienie do 60 sekund przy awarii
- ⚠️ Nie uruchomi się automatycznie po restarcie serwera

#### **Komendy:**
```bash
# Logi watchdog
ssh -p 65002 u923457281@46.17.175.219 "tail -f ~/promag/watchdog.log"

# Stop watchdog
ssh -p 65002 u923457281@46.17.175.219 "kill \$(cat ~/promag/watchdog.pid)"

# Restart watchdog
ssh -p 65002 u923457281@46.17.175.219 "~/promag/start_watchdog.sh"
```

---

### **2. Gunicorn (PRODUCTION-READY)**

Zamienia Flask development server na production WSGI server.

#### **Instalacja:**
```bash
chmod +x setup_gunicorn.sh
./setup_gunicorn.sh
```

#### **Zalety:**
- ✅ Production-ready server
- ✅ Lepsze performance
- ✅ Obsługa wielu workerów
- ✅ Automatyczny restart workerów
- ✅ Lepsze logowanie

#### **Wady:**
- ⚠️ Bardziej skomplikowane
- ⚠️ Nie uruchomi się automatycznie po restarcie serwera

#### **Komendy:**
```bash
# Stop
ssh -p 65002 u923457281@46.17.175.219 "kill \$(cat ~/promag/gunicorn.pid)"

# Restart (bez downtime)
ssh -p 65002 u923457281@46.17.175.219 "kill -HUP \$(cat ~/promag/gunicorn.pid)"

# Logi
ssh -p 65002 u923457281@46.17.175.219 "tail -f ~/promag/gunicorn_error.log"
```

---

### **3. Supervisor (NAJBARDZIEJ ZAAWANSOWANE)**

Profesjonalne narzędzie do zarządzania procesami.

#### **Instalacja:**
```bash
chmod +x setup_supervisor.sh
./setup_supervisor.sh
```

#### **Zalety:**
- ✅ Automatyczny restart przy awarii
- ✅ Zarządzanie wieloma procesami
- ✅ Web interface (opcjonalnie)
- ✅ Szczegółowe logi
- ✅ Restart bez downtime

#### **Wady:**
- ⚠️ Wymaga instalacji dodatkowego oprogramowania
- ⚠️ Może nie działać na niektórych hostingach
- ⚠️ Nie uruchomi się automatycznie po restarcie serwera (brak crontab)

#### **Komendy:**
```bash
# Status
ssh -p 65002 u923457281@46.17.175.219 "supervisorctl -c ~/supervisor/supervisord.conf status"

# Restart
ssh -p 65002 u923457281@46.17.175.219 "supervisorctl -c ~/supervisor/supervisord.conf restart promag"

# Logi
ssh -p 65002 u923457281@46.17.175.219 "tail -f ~/supervisor/logs/promag.out.log"
```

---

## 🎯 **Rekomendacja:**

### **Dla Hostinger: Watchdog + Gunicorn**

Najlepsza kombinacja stabilności i wydajności:

1. **Najpierw zainstaluj Gunicorn:**
   ```bash
   ./setup_gunicorn.sh
   ```

2. **Potem dodaj Watchdog:**
   Zmodyfikuj `setup_watchdog.sh` aby sprawdzał `gunicorn` zamiast `python.*app.py`

---

## 📊 **Porównanie:**

| Rozwiązanie | Łatwość | Stabilność | Performance | Auto-restart | Hostinger |
|-------------|---------|------------|-------------|--------------|-----------|
| **Watchdog** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ✅ |
| **Gunicorn** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | ✅ |
| **Supervisor** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | ⚠️ |
| **Watchdog + Gunicorn** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ |

---

## 🚀 **Quick Start (Watchdog):**

```bash
# 1. Zainstaluj watchdog
chmod +x setup_watchdog.sh
./setup_watchdog.sh

# 2. Sprawdź czy działa
curl https://promag.flavorinthejar.com/

# 3. Monitoruj logi
ssh -p 65002 u923457281@46.17.175.219 "tail -f ~/promag/watchdog.log"
```

---

## 📝 **Po restarcie serwera:**

Niestety Hostinger **nie wspiera crontab**, więc po restarcie serwera musisz:

1. **Uruchomić aplikację:**
   ```bash
   ./restart_app.sh
   ```

2. **Uruchomić watchdog:**
   ```bash
   ssh -p 65002 u923457281@46.17.175.219 "~/promag/start_watchdog.sh"
   ```

LUB stwórz jeden skrypt który zrobi to automatycznie:

```bash
./restart_app.sh && ssh -p 65002 u923457281@46.17.175.219 "~/promag/start_watchdog.sh"
```

---

## 💡 **Długoterminowe rozwiązanie:**

Jeśli chcesz **100% uptime** bez ręcznej interwencji po restarcie serwera, rozważ:

1. **VPS** (np. DigitalOcean, Linode, Vultr) - pełna kontrola, systemd, crontab
2. **Cloud Platform** (np. Heroku, Railway, Render) - automatyczne zarządzanie
3. **Kontener** (Docker + Docker Compose) - izolacja i łatwe wdrażanie

---

## ✅ **Następne kroki:**

1. Wybierz rozwiązanie (polecam **Watchdog**)
2. Uruchom odpowiedni skrypt setup
3. Monitoruj przez kilka dni
4. Jeśli stabilne - gotowe!
5. Jeśli nie - spróbuj **Watchdog + Gunicorn**
