# Clubby — infraestrutura

Este repositório guarda só o que orquestra os dois serviços no servidor:

```
clubby/                 ← este repo (clubby-infra)
├── docker-compose.yml  ← sobe demo + produção + Caddy (HTTPS)
├── deploy/
│   ├── Caddyfile       ← rotas demo./app./api./api-demo.
│   ├── .env.example    ← copie para deploy/.env no servidor
│   └── README.md       ← passo a passo de DNS e deploy
├── clubby-api/         ← clone de github.com/clubbyadmin/clubby-api (NestJS + Prisma)
└── clubby-web/         ← clone de github.com/clubbyadmin/clubby-web (Next.js)
```

`clubby-api/` e `clubby-web/` são ignorados aqui porque cada um tem o próprio repositório.

## Montar o ambiente do zero

```bash
git clone git@github.com:clubbyadmin/clubby-infra.git clubby
cd clubby
git clone git@github.com:clubbyadmin/clubby-api.git
git clone git@github.com:clubbyadmin/clubby-web.git
cp deploy/.env.example deploy/.env   # edite domínio, senhas e banco
docker compose --env-file deploy/.env --profile demo --profile prod --profile proxy up --build -d
```

Detalhes em [`deploy/README.md`](deploy/README.md).
