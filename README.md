# Clubby — infraestrutura

Este repositório guarda só o que orquestra a API no servidor. O front-end roda na Vercel.

```
clubby/                 ← este repo (clubby-infra)
├── docker-compose.yml  ← API demo + API produção + Caddy (HTTPS)
├── deploy/
│   ├── Caddyfile       ← rotas api-demo. e api.
│   ├── .env.example    ← copie para deploy/.env no VPS
│   └── README.md       ← passo a passo: Lightsail, Cloudflare, Vercel
├── clubby-api/         ← clone de github.com/clubbyadmin/clubby-api (NestJS + Prisma)
└── clubby-web/         ← clone de github.com/clubbyadmin/clubby-web (Next.js) — só no dev local
```

`clubby-api/` e `clubby-web/` são ignorados aqui porque cada um tem o próprio repositório.

## No VPS

```bash
git clone git@github.com:clubbyadmin/clubby-infra.git clubby
cd clubby
git clone git@github.com:clubbyadmin/clubby-api.git
cp deploy/.env.example deploy/.env   # edite domínio, segredos e Neon
docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up --build -d
```

Detalhes em [`deploy/README.md`](deploy/README.md).
