# 9Router Docker — Setup Guide

> [← Index](./README.md) · [Bahasa Indonesia](./README.id-ID.md)

Docker Compose stack for [9Router](https://github.com/decolua/9router): builds from the official [`9router`](https://www.npmjs.com/package/9router) npm package on `node:22-alpine`, persists state under `./data`, runs as a configurable non-root user.

**Dashboard (default):** http://127.0.0.1:20128

## Contents
- [Prerequisites](#prerequisites)
- [Deploy](#deploy)
- [Environment variables](#environment-variables)
- [Data persistence](#data-persistence)
- [Scripts](#scripts)
- [Operations](#operations)
- [Headroom sidecar](#headroom-sidecar)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Prerequisites
- Docker Engine + Docker Compose v2
- User in the `docker` group (or run compose with `sudo`)
- Container UID/GID — set `DOCKER_UID` and `DOCKER_GID` in `.env` (discover with `id <user>`)

## Deploy
### 1. Get the stack
```bash
git clone <url-repository>
cd 9router
```
Any install path works (e.g. `/opt/docker/9router`) as long as you run compose from the stack root.

### 2. Configure environment
```bash
cp .env.example .env
nano .env
```
Set at minimum `JWT_SECRET`, `INITIAL_PASSWORD`, and `DOCKER_UID` / `DOCKER_GID`. See [Environment variables](#environment-variables).

### 3. Initialize data permissions
```bash
sudo bash scripts/init-data-permissions.sh
```
Re-run after restoring `./data` from backup.

### 4. Build and start
```bash
docker compose build
docker compose up -d
```
Verify:
```bash
docker compose ps
bash scripts/healthcheck.sh
docker compose logs -f 9router
```

### 5. Connect coding tools
```bash
export OPENAI_BASE_URL="http://127.0.0.1:20128/v1"
export OPENAI_API_KEY="<api-key-from-9router-dashboard>"
```
For remote hosts, use SSH port forwarding or a reverse proxy — avoid binding `0.0.0.0` without firewall rules.

## Environment variables
### Required (production)
| Variable | Description |
| --- | --- |
| `JWT_SECRET` | JWT signing secret — `openssl rand -hex 32` |
| `INITIAL_PASSWORD` | Dashboard login password |

### Host / Compose
| Variable | Default | Description |
| --- | --- | --- |
| `DOCKER_UID` | `1000` | Container UID — must match `./data` ownership |
| `DOCKER_GID` | `1000` | Container GID |
| `NINE_ROUTER_BIND` | `127.0.0.1` | Host bind (`0.0.0.0` = all interfaces) |
| `NINE_ROUTER_PORT` | `20128` | Host and container port |
| `NINEROUTER_VERSION` | `latest` | npm version pin for image build |
| `IMAGE_NAME` | `9router-local` | Local Docker image name |
| `IMAGE_TAG` | `latest` | Image tag → `${IMAGE_NAME}:${IMAGE_TAG}` |

### 9Router application (optional)
| Variable | Default | Description |
| --- | --- | --- |
| `NINE_ROUTER_HOSTNAME` | `0.0.0.0` | Bind address inside container |
| `NODE_ENV` | `production` | Runtime mode |
| `BASE_URL` | *(auto)* | Server-side base URL |
| `CLOUD_URL` | *(auto)* | Cloud sync URL |
| `NEXT_PUBLIC_BASE_URL` | *(auto)* | Public dashboard base URL |
| `NEXT_PUBLIC_CLOUD_URL` | *(auto)* | Public cloud URL |
| `API_KEY_SECRET` | — | Endpoint-proxy API key secret |
| `MACHINE_ID_SALT` | — | Endpoint-proxy machine ID salt |
| `ENABLE_REQUEST_LOGS` | `false` | Verbose request logging |
| `DEBUG` | `false` | Debug mode |
| `HEADROOM_URL` | — | Headroom sidecar URL |

Official docs: [installation.md](https://github.com/decolua/9router/blob/master/gitbook/content/en/getting-started/installation.md) · [DOCKER.md](https://github.com/decolua/9router/blob/master/DOCKER.md)

## Data persistence
Bind mount: `./data` → `/app/data` (`DATA_DIR=/app/data`)
```text
data/
├── db/
│   ├── data.sqlite       # SQLite database
│   └── backups/          # automatic backups
└── ...                   # certs, logs, runtime configs
```
`data/` is gitignored; only `data/.gitkeep` is tracked.

## Scripts
| Script | Command |
| --- | --- |
| Init permissions | `sudo bash scripts/init-data-permissions.sh` |
| Health check | `bash scripts/healthcheck.sh` |
| Update | `bash scripts/update.sh` |

## Operations
| Task | Command |
| --- | --- |
| Logs | `docker compose logs -f 9router` |
| Stop | `docker compose stop` |
| Start | `docker compose start` |
| Update version | Set `NINEROUTER_VERSION` in `.env`, then `bash scripts/update.sh` |
| Change port | Set `NINE_ROUTER_PORT` in `.env`, then `docker compose up -d --force-recreate` |

Port mapping: `${NINE_ROUTER_BIND}:${NINE_ROUTER_PORT}:${NINE_ROUTER_PORT}` → container `PORT`.

## Headroom sidecar
9Router does not bundle Headroom. Run it as a separate container and set `HEADROOM_URL` in `.env`. See [DOCKER.md — Headroom sidecar](https://github.com/decolua/9router/blob/master/DOCKER.md).

## Troubleshooting
| Symptom | Fix |
| --- | --- |
| Container exits immediately | Check logs; verify `JWT_SECRET` and `INITIAL_PASSWORD` |
| Permission denied on `./data` | `sudo bash scripts/init-data-permissions.sh` |
| Port already in use | Change `NINE_ROUTER_PORT` in `.env` |
| Healthcheck failing | Wait 60s (`start_period`); test `curl http://127.0.0.1:20128/` |
| Wrong UID/GID | Update `DOCKER_UID` / `DOCKER_GID`, re-run init-data-permissions |

## References
- [9Router GitHub](https://github.com/decolua/9router)
- [9Router DOCKER.md](https://github.com/decolua/9router/blob/master/DOCKER.md)
- [otnansirk/9router-docker](https://github.com/otnansirk/9router-docker)
