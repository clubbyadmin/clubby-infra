# Evolution API no Lightsail (WhatsApp Clubby)

A Evolution roda **no mesmo VPS** do Clubby. O salão só vê o QR no Clubby;
a Evolution fica na infra.

## 1. DNS

Crie um registro **A**:

| Host | Aponta para |
| --- | --- |
| `evolution.clubby.com.br` | IP público do Lightsail |

Espere propagar (minutos).

## 2. Variáveis no `deploy/.env`

No VPS:

```bash
cd ~/clubby
nano deploy/.env
```

Remova placeholders (`sua-evolution.com`, `sua-apikey`) e use:

```bash
# Gere keys fortes:
#   openssl rand -hex 24
EVOLUTION_API_KEY=COLE_AQUI_A_CHAVE_GERADA
EVOLUTION_DB_PASSWORD=COLE_AQUI_OUTRA_SENHA
EVOLUTION_SERVER_URL=https://evolution.clubby.com.br
EVOLUTION_API_URL=http://evolution-api:8080
WHATSAPP_INBOUND_URL=https://api.clubby.com.br/whatsapp/inbound
```

Salve (`Ctrl+O`, Enter, `Ctrl+X`).

## 3. Subir a stack

```bash
cd ~/clubby
git pull origin main
cd clubby-api && git pull origin main && cd ..

docker compose --env-file deploy/.env \
  --profile demo --profile prod --profile proxy --profile whatsapp \
  up -d --build
```

## 4. Testar

Pelo host (HTTPS público):

```bash
set -a && source deploy/.env && set +a
curl -sS -H "apikey: $EVOLUTION_API_KEY" \
  "https://evolution.clubby.com.br"
```

Deve responder welcome da Evolution.

Pela rede interna (como a API Clubby faz):

```bash
docker compose --env-file deploy/.env exec api \
  wget -qO- --header="apikey: $EVOLUTION_API_KEY" \
  http://evolution-api:8080/
```

## 5. Conectar o primeiro salão

1. Abra a ficha do parceiro → aba **WhatsApp**
2. Clique **Conectar WhatsApp**
3. Escaneie o QR com o celular do estabelecimento
4. Status vira **Conectado**

## Troubleshooting

| Sintoma | Causa comum |
| --- | --- |
| `No host part in the URL` | `EVOLUTION_API_URL` vazia no shell / `.env` |
| `fetch failed` | Evolution ainda não subiu ou DNS sem `evolution.` |
| `pull access denied` / `atendai/evolution-api` | Imagem antiga; use `evoapicloud/evolution-api:v2.3.7` (já no compose) |
| Caddy 502 em evolution. | Profile `whatsapp` não foi usado no `up` |
| QR não gera | API Clubby antiga — faça `--build api` de novo |
