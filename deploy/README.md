# Hospedagem Clubby — demo e produção

## Arquitetura

```
                 Cloudflare (DNS)
                       │
   ┌───────────────────┼─────────────────────┐
   │                   │                     │
 demo.seudominio    app.seudominio      api-demo. / api.
   │                   │                     │
   ▼                   ▼                     ▼
 Vercel             Vercel          AWS Lightsail · São Paulo
 (clubby-web,       (clubby-web,    ┌──────────────────────────┐
  modo demo)         modo prod)     │ Caddy (HTTPS)            │
                                    │ api-demo ─► postgres-demo│  dados mock
                                    │ api      ─► Neon · main  │  produção
                                    └──────────────────────────┘
```

| Frente | Front | API | Banco |
| --- | --- | --- | --- |
| Demonstração | `demo.` (Vercel) | `api-demo.` (VPS) | Postgres no VPS, mock |
| Produção | `app.` (Vercel) | `api.` (VPS) | Neon · branch `main` |

Lightsail em `sa-east-1` fica na mesma região do Neon: latência API↔banco mínima.

## 1. VPS — AWS Lightsail

1. [lightsail.aws.amazon.com](https://lightsail.aws.amazon.com) → **Create instance**.
2. Região **São Paulo (sa-east-1)**. Plataforma Linux. Blueprint **OS only → Ubuntu 24.04**.
3. Plano: **2 GB RAM** é o mínimo confortável para duas APIs + Postgres + Caddy (≈ US$ 12/mês). 4 GB se quiser folga.
4. Nome `clubby-api`. Create.
5. Em **Networking** da instância: crie um **Static IP** e anexe. Anote o IP.
6. Ainda em Networking → **IPv4 Firewall**: adicione **HTTPS (443)**. SSH (22) e HTTP (80) já vêm abertos.

Conecte (botão **Connect using SSH** no painel, ou baixe a chave e use `ssh -i chave.pem ubuntu@IP`) e instale o Docker:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
exit   # reconecte para o grupo valer
```

## 2. DNS — Cloudflare

Em **DNS → Records** do domínio, crie (todos com **Proxy status = DNS only**, nuvem cinza, pelo menos até tudo funcionar):

| Tipo | Nome | Conteúdo |
| --- | --- | --- |
| A | `api` | IP estático do Lightsail |
| A | `api-demo` | IP estático do Lightsail |
| CNAME | `app` | `cname.vercel-dns.com` |
| CNAME | `demo` | `cname.vercel-dns.com` |

`@` e `www` podem apontar para a Vercel também (CNAME) ou para uma landing page futura.

Depois que tudo estiver no ar, pode ligar o proxy laranja em `api` e `api-demo`; aí ajuste **SSL/TLS → Full (strict)** no Cloudflare.

## 3. API no VPS

```bash
git clone git@github.com:clubbyadmin/clubby-infra.git clubby
cd clubby
git clone git@github.com:clubbyadmin/clubby-api.git
cp deploy/.env.example deploy/.env
nano deploy/.env        # domínio, segredos, DATABASE_URL_PROD (Neon · main)

docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up --build -d
docker compose logs -f api api-demo   # Ctrl+C para sair
```

Para o `git clone` por SSH funcionar no VPS, gere uma chave lá (`ssh-keygen -t ed25519`) e cadastre a pública como **Deploy key** nos repos `clubby-infra` e `clubby-api` no GitHub. Alternativa: clone por HTTPS se os repos forem públicos.

Teste: `https://api.seudominio/health` e `https://api-demo.seudominio/health` devem responder `{"ok":true,...}`.

Atualizar depois:

```bash
cd ~/clubby/clubby-api && git pull && cd .. && docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up --build -d
```

## 4. Front na Vercel — dois projetos, um repositório

Crie **dois projetos** na Vercel a partir do mesmo repo `clubbyadmin/clubby-web`:

### Projeto `clubby-web` (produção)

- **Framework:** Next.js (detectado). Root directory: `/`.
- **Environment Variables:**
  - `NEXT_PUBLIC_API_URL` = `https://api.seudominio`
  - `NEXT_PUBLIC_APP_MODE` = `production`
- **Domains:** adicione `app.seudominio`.

### Projeto `clubby-web-demo` (demonstração)

- Mesmo repo, mesma branch `main`.
- **Environment Variables:**
  - `NEXT_PUBLIC_API_URL` = `https://api-demo.seudominio`
  - `NEXT_PUBLIC_APP_MODE` = `demo`
- **Domains:** adicione `demo.seudominio`.

Cada push em `main` publica os dois. Anote as URLs `*.vercel.app` de cada projeto e coloque em `DEMO_CORS_ORIGINS` / `PROD_CORS_ORIGINS` no `deploy/.env` do VPS.

## 5. Bancos de dados: quem aponta para onde

| Ambiente | Banco | Observação |
| --- | --- | --- |
| Sua máquina | Neon · branch `development` | Sandbox. Pode criar, apagar, testar à vontade. |
| Demo (`demo.`) | Postgres no Docker do VPS | Mock, isolado, recriado pelo seed. |
| Produção (`app.`) | Neon · branch `main` | Dados reais. Só a API do VPS conecta aqui. |

Dados **não** viajam entre bancos. O que viaja é código: uma mudança de schema
nasce localmente com `prisma migrate dev` (arquivo em `prisma/migrations/`),
vai para o git, e a API de produção aplica o mesmo arquivo com
`prisma migrate deploy` ao subir o container.

Para "zerar" o `development` para o estado atual da produção: no Neon, apague o
branch e crie outro a partir do `main`; depois atualize o `.env` local.

## 6. Primeiro acesso em produção

O banco de produção não recebe seed automático. A API roda
`prisma migrate deploy` ao subir, então o schema fica em dia sozinho. Entre em
`app.seudominio/login` como `admin@clubby.com.br` com a `SUPER_ADMIN_PASSWORD`
do `deploy/.env` e crie o primeiro parceiro pelo painel.

## 7. Apresentar antes de tudo isso existir

Localmente já funciona em modo demo: `APP_ENV=demo` em `clubby-api/.env`,
`NEXT_PUBLIC_APP_MODE=demo` em `clubby-web/.env.local`, e abra
`http://localhost:3001/login`. Logins: `admin@clubby.com.br`,
`admin@demo-barber.clubby` / `clubby-admin`. Loja mock em `/demo-barber`.
