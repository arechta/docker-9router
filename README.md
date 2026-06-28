# 9Router — Docker Deployment

Self-hosted [9Router](https://github.com/decolua/9router) stack: **source build** from patched `repository/` (upstream `decolua/9router` + local patches), persistent `./data` volume, non-root container user.

Routes AI API calls from coding tools (Cursor, Claude Code, Copilot, etc.) to multiple providers with fallback, quota tracking, and token optimization.

## Documentation
| Language | Guide |
| --- | --- |
| English (US) | [README.en-US.md](./README.en-US.md) |
| Bahasa Indonesia | [README.id-ID.md](./README.id-ID.md) |

## Quick Start
```bash
cp .env.example .env    # edit JWT_SECRET, INITIAL_PASSWORD, DOCKER_UID/GID
bash scripts/sync-repository.sh
sudo bash scripts/init-data-permissions.sh
docker compose up -d --build
bash scripts/healthcheck.sh
```
Dashboard: **http://127.0.0.1:20128** (default port)

## Links
- [9Router (official)](https://github.com/decolua/9router)
- [DOCKER.md](https://github.com/decolua/9router/blob/master/DOCKER.md)
- [otnansirk/9router-docker](https://github.com/otnansirk/9router-docker) — layout reference

## File Layout
```text
9router/
├── Dockerfile
├── docker-compose.yml
├── docker-entrypoint.sh
├── patches/              # local fixes applied to upstream (see patches/README.md)
├── repository/           # decolua/9router clone (gitignored; sync via script)
├── .env.example
├── .env                  # gitignored — copy from .env.example
├── data/                 # persistent volume (SQLite, configs, logs)
└── scripts/
    ├── init-data-permissions.sh
    ├── healthcheck.sh
    └── update.sh
```
