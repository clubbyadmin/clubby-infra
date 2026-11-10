#!/usr/bin/env bash
# Diagnóstico: cria/conecta uma instância e mostra o JSON do QR.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY=$(grep -E '^EVOLUTION_API_KEY=' deploy/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
URL=${EVOLUTION_API_URL:-http://evolution-api:8080}
INSTANCE=${1:-clubby-qr-diagnostico}

if [[ -z "$KEY" ]]; then
  echo "EVOLUTION_API_KEY vazia no deploy/.env"
  exit 1
fi

echo "== KEY len: ${#KEY}"
echo "== URL: $URL"
echo "== INSTANCE: $INSTANCE"
echo

echo "== 1) Welcome"
docker run --rm --network clubby_default curlimages/curl:8.5.0 \
  -sS -H "apikey: $KEY" "$URL/" || true
echo
echo

echo "== 2) Create (ignore se já existir)"
docker run --rm --network clubby_default curlimages/curl:8.5.0 \
  -sS -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d "{\"instanceName\":\"$INSTANCE\",\"qrcode\":true,\"integration\":\"WHATSAPP-BAILEYS\"}" \
  "$URL/instance/create" || true
echo
echo

echo "== 3) Logout"
docker run --rm --network clubby_default curlimages/curl:8.5.0 \
  -sS -X DELETE -H "apikey: $KEY" \
  "$URL/instance/logout/$INSTANCE" || true
echo
echo
sleep 2

echo "== 4) Connect (QR)"
docker run --rm --network clubby_default curlimages/curl:8.5.0 \
  -sS -H "apikey: $KEY" \
  "$URL/instance/connect/$INSTANCE"
echo
echo

echo "== 5) Connection state"
docker run --rm --network clubby_default curlimages/curl:8.5.0 \
  -sS -H "apikey: $KEY" \
  "$URL/instance/connectionState/$INSTANCE"
echo
