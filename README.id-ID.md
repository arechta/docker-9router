# 9Router Docker — Panduan Setup

> [← Index](./README.md) · [English (US)](./README.en-US.md)

Stack Docker Compose untuk [9Router](https://github.com/decolua/9router): image dibangun dari paket npm resmi `[9router](https://www.npmjs.com/package/9router)` di `node:22-alpine`, data disimpan di `./data`, berjalan sebagai user non-root yang dapat dikonfigurasi.

**Dashboard (default):** [http://127.0.0.1:20128](http://127.0.0.1:20128)

9Router adalah proxy MITM lokal yang mengarahkan panggilan API AI dari alat coding (Cursor, Claude Code, Copilot, dll.) ke banyak provider dengan fallback otomatis, pelacakan kuota, dan optimasi token.

## Daftar isi

- [Prasyarat](#prasyarat)
- [Deploy](#deploy)
- [Variabel environment](#variabel-environment)
- [Persistensi data](#persistensi-data)
- [Script](#script)
- [Operasional](#operasional)
- [Sidecar Headroom](#sidecar-headroom)
- [Troubleshooting](#troubleshooting)
- [Referensi](#referensi)

## Prasyarat

- Docker Engine + Docker Compose v2
- User ada di grup `docker` (atau jalankan compose dengan `sudo`)
- UID/GID container — set `DOCKER_UID` dan `DOCKER_GID` di `.env` (cek dengan `id <user>`)

## Deploy

### 1. Dapatkan stack

```bash
git clone <url-repository>
cd 9router
```

Path instalasi bebas (mis. `/opt/docker/9router`) asalkan compose dijalankan dari root stack.

### 2. Konfigurasi environment

```bash
cp .env.example .env
nano .env
```

Minimal set `JWT_SECRET`, `INITIAL_PASSWORD`, dan `DOCKER_UID` / `DOCKER_GID`. Lihat [Variabel environment](#variabel-environment).

### 3. Inisialisasi permission data

```bash
sudo bash scripts/init-data-permissions.sh
```

Jalankan ulang setelah restore `./data` dari backup.

### 4. Build dan jalankan

```bash
docker compose build
docker compose up -d
```

Verifikasi:

```bash
docker compose ps
bash scripts/healthcheck.sh
docker compose logs -f 9router
```

### 5. Hubungkan alat coding

```bash
export OPENAI_BASE_URL="http://127.0.0.1:20128/v1"
export OPENAI_API_KEY="<api-key-dari-dashboard-9router>"
```

Untuk host remote, gunakan SSH port forwarding atau reverse proxy — hindari bind `0.0.0.0` tanpa firewall.

## Variabel environment



### Wajib (production)


| Variabel           | Keterangan                          |
| ------------------ | ----------------------------------- |
| `JWT_SECRET`       | Secret JWT — `openssl rand -hex 32` |
| `INITIAL_PASSWORD` | Password login dashboard            |




### Host / Compose


| Variabel             | Default         | Keterangan                                           |
| -------------------- | --------------- | ---------------------------------------------------- |
| `DOCKER_UID`         | `1000`          | UID container — harus sama dengan ownership `./data` |
| `DOCKER_GID`         | `1000`          | GID container                                        |
| `NINE_ROUTER_BIND`   | `127.0.0.1`     | Bind host (`0.0.0.0` = semua interface)              |
| `NINE_ROUTER_PORT`   | `20128`         | Port host dan container                              |
| `NINEROUTER_VERSION` | `latest`        | Versi npm saat build image                           |
| `IMAGE_NAME`         | `9router-local` | Nama image Docker lokal                              |
| `IMAGE_TAG`          | `latest`        | Tag image → `${IMAGE_NAME}:${IMAGE_TAG}`             |




### Aplikasi 9Router (opsional)


| Variabel                | Default      | Keterangan                      |
| ----------------------- | ------------ | ------------------------------- |
| `NINE_ROUTER_HOSTNAME`  | `0.0.0.0`    | Bind address di dalam container |
| `NODE_ENV`              | `production` | Mode runtime                    |
| `BASE_URL`              | *(otomatis)* | Base URL sisi server            |
| `CLOUD_URL`             | *(otomatis)* | URL sinkronisasi cloud          |
| `NEXT_PUBLIC_BASE_URL`  | *(otomatis)* | Base URL publik dashboard       |
| `NEXT_PUBLIC_CLOUD_URL` | *(otomatis)* | URL cloud publik                |
| `API_KEY_SECRET`        | —            | Secret API key endpoint-proxy   |
| `MACHINE_ID_SALT`       | —            | Salt machine ID endpoint-proxy  |
| `ENABLE_REQUEST_LOGS`   | `false`      | Log request verbose             |
| `DEBUG`                 | `false`      | Mode debug                      |
| `HEADROOM_URL`          | —            | URL sidecar Headroom            |


Dokumentasi resmi: [installation.md](https://github.com/decolua/9router/blob/master/gitbook/content/en/getting-started/installation.md) · [DOCKER.md](https://github.com/decolua/9router/blob/master/DOCKER.md)

## Persistensi data

Bind mount: `./data` → `/app/data` (`DATA_DIR=/app/data`)

```text
data/
├── db/
│   ├── data.sqlite       # database SQLite
│   └── backups/          # backup otomatis
└── ...                   # sertifikat, log, konfigurasi runtime
```

Folder `data/` di-gitignore; hanya `data/.gitkeep` yang di-track.

## Script


| Script          | Perintah                                     |
| --------------- | -------------------------------------------- |
| Init permission | `sudo bash scripts/init-data-permissions.sh` |
| Health check    | `bash scripts/healthcheck.sh`                |
| Update          | `bash scripts/update.sh`                     |




## Operasional


| Tugas        | Perintah                                                                       |
| ------------ | ------------------------------------------------------------------------------ |
| Log          | `docker compose logs -f 9router`                                               |
| Stop         | `docker compose stop`                                                          |
| Start        | `docker compose start`                                                         |
| Update versi | Set `NINEROUTER_VERSION` di `.env`, lalu `bash scripts/update.sh`              |
| Ubah port    | Set `NINE_ROUTER_PORT` di `.env`, lalu `docker compose up -d --force-recreate` |


Mapping port: `${NINE_ROUTER_BIND}:${NINE_ROUTER_PORT}:${NINE_ROUTER_PORT}` → `PORT` di container.

## Sidecar Headroom

9Router tidak menyertakan Headroom. Jalankan sebagai container terpisah dan set `HEADROOM_URL` di `.env`. Lihat [DOCKER.md — Headroom sidecar](https://github.com/decolua/9router/blob/master/DOCKER.md).

## Troubleshooting


| Gejala                        | Solusi                                                                   |
| ----------------------------- | ------------------------------------------------------------------------ |
| Container langsung exit       | Cek log; pastikan `JWT_SECRET` dan `INITIAL_PASSWORD` sudah di-set       |
| Permission denied di `./data` | `sudo bash scripts/init-data-permissions.sh`                             |
| Port sudah dipakai            | Ubah `NINE_ROUTER_PORT` di `.env`                                        |
| Healthcheck gagal             | Tunggu 60s (`start_period`); tes `curl http://127.0.0.1:20128/`          |
| UID/GID salah                 | Update `DOCKER_UID` / `DOCKER_GID`, jalankan ulang init-data-permissions |




## Referensi

- [9Router GitHub](https://github.com/decolua/9router)
- [9Router DOCKER.md](https://github.com/decolua/9router/blob/master/DOCKER.md)
- [otnansirk/9router-docker](https://github.com/otnansirk/9router-docker)

