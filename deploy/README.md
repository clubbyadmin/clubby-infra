# Hospedagem Clubby — demo e produção

Duas frentes no mesmo domínio:

| Frente | URL | O que é |
| --- | --- | --- |
| Demonstração | `https://demo.seudominio` | Dados mock, WhatsApp falso, banco isolado. Serve para apresentar a clientes. |
| Produção | `https://app.seudominio` | Ambiente real (Neon/Postgres de produção). Sem seed automático. |

APIs: `https://api-demo.seudominio` e `https://api.seudominio`.

## 1. DNS

No provedor do domínio, aponte para o IP do VPS:

```
A     @              IP_DO_VPS
A     www            IP_DO_VPS
A     app            IP_DO_VPS
A     api            IP_DO_VPS
A     demo           IP_DO_VPS
A     api-demo       IP_DO_VPS
```

## 2. Configurar o servidor

```bash
cp deploy/.env.example deploy/.env
# edite CLUBBY_DOMAIN, senhas, DATABASE_URL_PROD e CADDY_EMAIL
```

Na raiz do projeto (`clubby/`):

```bash
# só a demonstração (também funciona em localhost, sem DNS)
docker compose --env-file deploy/.env --profile demo up --build -d

# produção + HTTPS (precisa do DNS apontando)
docker compose --env-file deploy/.env --profile prod --profile proxy up --build -d

# as duas frentes no mesmo VPS
docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up --build -d
```

Caddy emite o certificado Let's Encrypt automaticamente.

## 3. Apresentar agora, sem domínio

Com a API e o Next locais:

1. Em `clubby-api/.env` acrescente `APP_ENV=demo`.
2. Em `clubby-web/.env.local` acrescente `NEXT_PUBLIC_APP_MODE=demo`.
3. Suba `npm run start:dev` (API) e `npm run dev` (web).
4. Abra `http://localhost:3001/login`.

Logins da demo:

- Super-Admin: `admin@clubby.com.br`
- Gestor: `admin@demo-barber.clubby`
- Recepção: `recepcao@demo-barber.clubby`

A senha padrão do catálogo demo é `clubby-admin` (Super-Admin usa a senha configurada em `SUPER_ADMIN_PASSWORD`, padrão local `admin123`).

A loja pública mock fica em `/demo-barber`.

## 4. O que muda entre os ambientes

**Demo:** seed do Studio + tenant `demo-barber`, WhatsApp MOCK, `/test-tools/seed` liberado, faixa “Ambiente de demonstração”, atalhos no login.

**Produção:** sem seed, sem test-tools, JWT e senha do Super-Admin obrigatórios, CORS só no domínio, Swagger desligado.

## 5. Primeiro deploy de produção

O banco de produção não é preenchido sozinho. Use o Neon (ou Postgres) já migrado:

A API roda `prisma migrate deploy` na subida do container.
