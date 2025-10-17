#!/bin/bash

# Skrypt wywoływany przez GitHub webhook
# Automatycznie aktualizuje kod i restartuje aplikację

LOG_FILE="$HOME/promag/deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

log "🔔 GitHub Webhook triggered!"

# Przejdź do katalogu projektu
cd ~/promag || exit 1

# Pobierz najnowszy kod z GitHub
log "📥 Pulling from GitHub..."
git pull origin main >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log "✅ Code updated successfully"
    
    # Restart aplikacji przez Supervisor
    log "🔄 Restarting application..."
    ~/.local/bin/supervisorctl -c ~/supervisor/supervisord.conf restart promag >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log "✅ Application restarted successfully"
        log "🎉 Deploy completed!"
    else
        log "❌ Failed to restart application"
    fi
else
    log "❌ Failed to pull from GitHub"
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
