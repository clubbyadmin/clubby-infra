#!/usr/bin/env bash
# Simula um "oi" chegando no webhook do Clubby (como a Evolution faria).
set -euo pipefail
cd "$(dirname "$0")/.."

KEY=$(grep -E '^EVOLUTION_API_KEY=' deploy/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
INSTANCE=${1:-clubby-studio-barber-teste}
PHONE=${2:-5511999990000}

echo "POST inbound instance=$INSTANCE from=$PHONE"
docker run --rm --network clubby_default curlimages/curl:8.5.0 \
  -sS -X POST \
  -H "Content-Type: application/json" \
  -H "apikey: $KEY" \
  -d "{\"event\":\"messages.upsert\",\"instance\":\"$INSTANCE\",\"data\":{\"key\":{\"remoteJid\":\"$PHONE@s.whatsapp.net\",\"fromMe\":false,\"id\":\"TEST\"},\"message\":{\"conversation\":\"oi\"},\"messageType\":\"conversation\"}}" \
  http://api:3000/whatsapp/inbound
echo
