# Produção Clubby — acesso ao portal e deploy

Guia operacional para o ambiente **real** (`app.` + `api.`).  
Demonstração (`demo.` / `api-demo.`) fica isolada e não compartilha banco.

---

## Mapa rápido

| Peça | URL | Onde roda |
| --- | --- | --- |
| Portal do cliente / gestão | `https://app.clubby.com.br` | Vercel · projeto `clubby-web` |
| API de produção | `https://api.clubby.com.br` | Lightsail · container `api` |
| Super-admin (plataforma) | `https://app.clubby.com.br/super-admin` | mesmo front |
| Login da equipe | `https://app.clubby.com.br/login` | mesmo front |
| Cadastro de salão | `https://app.clubby.com.br/parceiro` | mesmo front |
| Vitrine do salão | `https://app.clubby.com.br/{slug}` | mesmo front |

Banco: **Neon · branch `main`** (só a API de produção usa).  
Não copie dados do demo Postgres para o Neon.

---

## 1. Quem entra onde

### 1.1 Super-Admin Clubby (você)

1. Abra `https://app.clubby.com.br/login`
2. E-mail: `admin@clubby.com.br`
3. Senha: valor de `SUPER_ADMIN_PASSWORD` no `deploy/.env` do VPS
4. Em produção a API envia um **código MFA no e-mail** (SMTP obrigatório)
5. Depois do código, o aparelho fica confiado ~30 dias
6. Destino: `/super-admin` — aprovar salões, taxas, status

O usuário nasce sozinho na subida da API (bootstrap), sem seed de catálogo demo.

### 1.2 Gestão do salão (dono / recepção / barbeiro)

1. O salão precisa estar `ACTIVE` (aprovado no super-admin)
2. Cada integrante entra com **e-mail + senha** em `/login` (e-mail obrigatório)
3. MFA no e-mail no primeiro aparelho; depois o aparelho pode ser pulado
4. Destino: `/admin` — agenda, clientes, WhatsApp, financeiro, etc.

Não existe auto-login em produção. Sem sessão válida, `/admin` manda para `/login`.

### 1.3 Cliente final do salão

1. Abre o link do salão: `https://app.clubby.com.br/{slug}`
2. Entra com e-mail (código SMTP) ou Google/Apple/Microsoft (se configurados)
3. Confirma o **celular** (obrigatório — liga a ficha aberta pelo WhatsApp)
4. Só então vê vitrine, agenda e área do cliente

---

## 2. Fluxo do primeiro salão real

```
1. Você sobe API + front de produção (seções 3 e 4)
2. Configura SMTP + SUPER_ADMIN_PASSWORD + JWT (seção 5)
3. Entra como admin@clubby.com.br
4. Barbeiro (ou você) preenche /parceiro  →  tenant PENDING
5. Você abre a ficha em /super-admin/parceiros/{id}
   (dados do estabelecimento, responsável, CEP e contrato SaaS)
6. Gera / registra o contrato e aprova → tenant ACTIVE
7. Gestor entra com o e-mail cadastrado →  /admin
8. Cliente usa /{slug}
```

A lista em `/super-admin` só resume. A ficha completa (cadastro + contrato
imprimível/PDF) fica em `/super-admin/parceiros/{id}` — clique no nome ou
use **Abrir ficha do cliente**.

Checklist mínimo no painel do salão depois de ACTIVE:

- [ ] Serviços
- [ ] Equipe (cada um com e-mail)
- [ ] Horário da casa (Agenda)
- [ ] WhatsApp (provedor real, não MOCK)
- [ ] Compartilhar o link `/{slug}`

---

## 3. Deploy da API (Lightsail)

SSH no VPS (usuário `ubuntu`), pasta do projeto:

```bash
cd ~/clubby
```

### 3.1 Atualizar só a API de produção

```bash
cd ~/clubby/clubby-api
git pull origin main
cd ~/clubby
docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up -d --build api
```

O container `api` sobe com `APP_ENV=production`, aplica `prisma migrate deploy` no Neon e sobe o Nest.

Conferir:

```bash
docker compose --env-file deploy/.env logs -f api
curl -s https://api.clubby.com.br/health
```

Resposta esperada: JSON com `ok: true` (ou equivalente do health).

### 3.2 Atualizar demo + produção + proxy (rebuild completo)

```bash
cd ~/clubby/clubby-api && git pull origin main
cd ~/clubby
docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up -d --build
```

### 3.3 Importante

- Sempre use `--env-file deploy/.env` (o Compose não lê sozinho esse arquivo).
- Serviço de produção = `api` (não `api-demo`).
- Não rode seed de demo no Neon main.
- Não exporte `DATABASE_URL` / senhas no chat ou em prints.

---

## 4. Deploy do front (Vercel)

Repositório: `clubbyadmin/clubby-web` · branch `main`.

### Projeto de produção (`clubby-web`)

| Variável | Valor |
| --- | --- |
| `NEXT_PUBLIC_API_URL` | `https://api.clubby.com.br` |
| `NEXT_PUBLIC_APP_MODE` | `production` |

Domínio: `app.clubby.com.br`

### Como publicar uma mudança do site

Na sua máquina (depois do commit):

```bash
cd /home/clubbydev/projects/clubby/clubby-web
git push origin HEAD
```

A Vercel publica sozinha. Front **não** precisa de pull no Lightsail.

### Projeto demo (não confundir)

| Variável | Valor |
| --- | --- |
| `NEXT_PUBLIC_API_URL` | `https://api-demo.clubby.com.br` |
| `NEXT_PUBLIC_APP_MODE` | `demo` |

Domínio: `demo.clubby.com.br`

---

## 5. Variáveis obrigatórias em produção

Arquivo no VPS: `~/clubby/deploy/.env`  
Modelo: `deploy/.env.example` e `clubby-api/.env.example`.

### API (`deploy/.env`)

| Variável | Função |
| --- | --- |
| `CLUBBY_DOMAIN` | `clubby.com.br` |
| `CADDY_EMAIL` | e-mail do Let’s Encrypt |
| `DATABASE_URL_PROD` | Neon main (pooler) |
| `JWT_SECRET_PROD` | segredo JWT (forte) |
| `SUPER_ADMIN_PASSWORD` | senha de `admin@clubby.com.br` |
| `PROD_CORS_ORIGINS` | URL `*.vercel.app` do projeto prod |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` | envio de códigos |
| `MAIL_FROM` | remetente, ex. `Clubby <noreply@clubby.com.br>` |
| `API_PUBLIC_URL` | `https://api.clubby.com.br` |
| `WEB_PUBLIC_URL` | `https://app.clubby.com.br` |
| `WHATSAPP_VERIFY_TOKEN` | verificação do webhook Meta (se usar) |

Sem SMTP em produção: login da gestão e código de e-mail do cliente **travam**.

OAuth do cliente (Google / Apple / Microsoft) — recomendado em produção:

No `deploy/.env` da API:

- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`
- `MICROSOFT_CLIENT_ID` / `MICROSOFT_CLIENT_SECRET`
- `APPLE_CLIENT_ID` / `APPLE_TEAM_ID` / `APPLE_KEY_ID` / `APPLE_PRIVATE_KEY`

Callback registrado em **cada** provedor (URI de redirecionamento):

`https://api.clubby.com.br/auth/customer/callback`

Sem essas chaves, os botões Google/Apple/Microsoft mostram erro na hora de abrir; o e-mail com código SMTP continua funcionando.

Asaas (só se o clube online entrar no piloto):

- `ASAAS_API_KEY`
- `ASAAS_API_URL` = URL **de produção** (não sandbox)
- `ASAAS_WEBHOOK_TOKEN`

### Front (Vercel · produção)

Já listado na seção 4. Não coloque segredos SMTP/JWT no front.

---

## 6. Ordem recomendada de um release

1. Migrar/schema local → commit em `clubby-api`
2. `git push` do `clubby-api`
3. No VPS: `git pull` + rebuild do serviço `api`
4. Commit/push do `clubby-web` (se houver mudança de UI)
5. Esperar deploy Vercel do projeto **production**
6. Testar:
   - `https://api.clubby.com.br/health`
   - `https://app.clubby.com.br/login` (super-admin + MFA)
   - Aprovar/abrir um salão de teste
   - Abrir `/{slug}` como cliente

---

## 7. Troubleshooting rápido

| Sintoma | O que checar |
| --- | --- |
| `/admin` pede login e não entra sozinho | Correto em produção. Use `/login`. |
| “Envio de e-mail ainda não está configurado” | `SMTP_*` e `MAIL_FROM` no `deploy/.env` + rebuild `api` |
| Código MFA não chega | SMTP, spam, `MAIL_FROM` do domínio autenticado |
| Front chama API errada | `NEXT_PUBLIC_API_URL` no projeto Vercel de **produção** |
| CORS no browser | `PROD_CORS_ORIGINS` + domínio `app.` no `CLUBBY_DOMAIN` |
| SUPER_ADMIN não existe | Logs do container `api` no boot (`Bootstrap` / `SUPER_ADMIN`); senha = `SUPER_ADMIN_PASSWORD` |
| Migração falhou | `docker compose ... logs api` — Neon main e `DATABASE_URL_PROD` |
| Salão PENDING | Aprovar em `/super-admin` antes do cliente abrir `/{slug}` |

---

## 8. O que ainda não é obrigatório no primeiro piloto

- Checkout Asaas do corte avulso (caixa presencial basta)
- Split de carteira profissional
- Subdomínio por salão (`slug.clubby.com.br`)
- Código numérico para achar o salão
- Lembretes WhatsApp via Meta Graph (hoje a saída automática usa Evolution/Webhook configurado no salão)

Para arquitetura geral demo×prod e setup inicial do VPS, veja também [README.md](./README.md).
