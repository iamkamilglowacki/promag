#!/bin/bash

# Pokaż logi aplikacji w czasie rzeczywistym

echo "📋 Logi aplikacji (Ctrl+C aby zatrzymać)"
echo "========================================="
echo ""

ssh -p 65002 u923457281@46.17.175.219 "tail -f ~/supervisor/logs/promag.out.log"
