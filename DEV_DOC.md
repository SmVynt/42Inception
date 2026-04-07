# Developer documentation — Inception

How to reproduce the environment, build, run, and debug the project.

## Prerequisites

- **OS:** Linux **virtual machine**.
- **Packages:** `docker.io`, **Docker Compose plugin** (`docker compose`), `git`, `make`, `sudo`.
- **Optional:** run **`./setup_vm.sh`** from the repo on a fresh VM to install Docker, OpenSSH, and print port-forward hints.
- **User:** Work as a normal user in the **docker** group (`sudo usermod -aG docker "$USER"` then **log out and back in**).
- **Disk:** Space for images plus persistent data under **`/home/<login>/data/`**.

## Repository layout

```
.
├── Makefile                 # drives compose; exports WP_VOLUME, DB_VOLUME, PT_VOLUME, DOMAIN_NAME
├── secrets/                 # real secrets gitignored; *.example committed
├── README.md, USER_DOC.md, DEV_DOC.md
└── srcs/
    ├── docker-compose.yml   # services, networks, volumes, secrets
    ├── .env                 # from .env.example — local only, no passwords
    └── requirements/
        ├── nginx/           # Dockerfile, conf/default_with_env.conf, tools/setup_nginx.sh
        ├── wordpress/       # Dockerfile, conf/www.conf, tools/setup_wordpress.sh
        ├── mariadb/         # Dockerfile, conf/, tools/setup_maria.sh
        └── bonus/
            ├── redis/       # Dockerfile, tools/setup_redis.sh
            ├── ftp-server/  # Dockerfile, config/vsftpd.conf, tools/setup_ftp.sh
            ├── adminer/     # Dockerfile, tools/adminer-*.php, tools/setup_adminer.sh
            ├── web/         # Dockerfile, tools/setup_web.sh, tools/site/ (Next.js app)
            └── portainer/   # Dockerfile, tools/setup_portainer.sh
```

Subject constraint: everything needed to configure the project lives under **`srcs/`** (plus Makefile and secrets at root).

## Configuration files and secrets

### `srcs/.env`

Copy from **`srcs/.env.example`** (or run `make` / `make init-secrets`).

**Core:**
- `MARIA_DATABASE`, `MARIA_USER`, `MARIA_PORT`
- `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WORDPRESS_TITLE`
- `WP_USER`, `WP_USER_EMAIL`
- `WORDPRESS_VERSION`

**Bonus:**
- `REDIS_HOST`, `REDIS_PORT`
- `ADMINER_PORT`
- `FTP_USER`, `FTP_PORT`, `FTP_PASV_ADDRESS`, `PASV_MIN_PORT`, `PASV_MAX_PORT`
- `WEB_PORT`
- `PORTAINER_PORT`

**Do not** put passwords here. `DOMAIN_NAME` is exported by the Makefile as `<login>.42.fr`.

### `secrets/*.txt`

One file per secret, **single line** (scripts strip newlines). Examples are in **`secrets/*.example`**.

| File | Consumed by |
|------|-------------|
| `db_password.txt` | MariaDB (app user), WordPress (DB) |
| `db_root_password.txt` | MariaDB root |
| `wp_password.txt` | WordPress administrator |
| `wp_author_password.txt` | Second WP user (author) |
| `redis_password_bonus.txt` | Redis AUTH, WordPress Redis plugin |
| `ftp_password_bonus.txt` | vsftpd FTP user |

Compose mounts them as **secrets**; entrypoints read **`/run/secrets/<name>`**.

## Build and launch

From the **repository root**:

```bash
make              # mkdir -p ~/data/{wordpress,mariadb,port}, seed .env / secrets if missing
make up           # docker compose up -d --build (with exported env)
```

Environment exported by Make for Compose:

- **`WP_VOLUME`** — host path for WordPress files volume (default `/home/<user>/data/wordpress`)
- **`DB_VOLUME`** — host path for MariaDB data volume (default `/home/<user>/data/mariadb`)
- **`PT_VOLUME`** — host path for Portainer data volume (default `/home/<user>/data/port`)
- **`DOMAIN_NAME`** — TLS CN and WordPress URL host (default `<user>.42.fr`)

Override by exporting before `make` or editing the Makefile for local dev.

Other useful targets:

| Target | Action |
|--------|--------|
| `make build` | `docker compose build` |
| `make rebuild` | `build --no-cache` then `up -d` |
| `make down` | stop stack |
| `make logs` | `docker compose logs -f` |
| `make clean` | `compose down -v` + `sudo rm -rf` data dirs |
| `make fclean` | `clean` + remove `secrets/*.txt` and `srcs/.env` (prompt) |
| `make help` | short help |


## Where data persists

| Data | Volume name in Compose | Host location |
|------|-------------------------|---------------|
| WordPress files | `wordpress_data` | `$WP_VOLUME` (default `~/data/wordpress`) |
| MariaDB files | `mariadb_data` | `$DB_VOLUME` (default `~/data/mariadb`) |
| Portainer data | `port_data` | `$PT_VOLUME` (default `~/data/port`) |

`make clean` runs **`down -v`** (removes those Compose volumes) and deletes the host directories.

The **Docker socket** (`/var/run/docker.sock`) is bind-mounted read-only into the Portainer container so it can manage the local Docker engine.

## Images and services

All images are **built locally** from `debian:bookworm-slim`. No pre-made service images are pulled from Docker Hub.

| Service | Base | Entrypoint | Notes |
|---------|------|------------|-------|
| `nginx` | debian:bookworm-slim | `setup_nginx.sh` | Generates self-signed cert; runs `envsubst` on nginx conf to inject `$DOMAIN_NAME`; starts `nginx -g 'daemon off;'` |
| `wordpress` | debian:bookworm-slim | `setup_wordpress.sh` | Installs WordPress via WP-CLI; configures Redis object cache plugin; starts `php-fpm` |
| `mariadb` | debian:bookworm-slim | `setup_maria.sh` | Initialises DB and users on first start; runs `mariadbd` |
| `redis` | debian:bookworm-slim | `setup_redis.sh` | Starts `redis-server` with AUTH password |
| `ftp-server` | debian:bookworm-slim | `setup_ftp.sh` | Creates FTP user mapped to `www-data` UID; writes vsftpd config; starts `vsftpd` |
| `adminer` | debian:bookworm-slim | `setup_adminer.sh` | Serves a single-file Adminer PHP app via `php -S` |
| `web` | debian:bookworm-slim | `setup_web.sh` | Installs Node.js 22 via NodeSource; runs `npm install` at build time; starts `next dev` |
| `portainer` | debian:bookworm-slim | `setup_portainer.sh` | Downloads Portainer CE binary from GitHub releases at build time; starts `portainer` |

## NGINX routing

NGINX listens on **443 (HTTPS)** only and routes by `server_name`:

| `server_name` | Upstream |
|---------------|----------|
| `<login>.42.fr` | WordPress PHP-FPM on `wordpress:9000` (FastCGI) |
| `adminer.<login>.42.fr` | `http://adminer:8080` (reverse proxy) |
| `web.<login>.42.fr` | `http://web:3000` (reverse proxy + WebSocket upgrade for HMR) |
| `portainer.<login>.42.fr` | `http://portainer:9000` (reverse proxy + WebSocket upgrade) |

The nginx config template is at `srcs/requirements/nginx/conf/default_with_env.conf`. `setup_nginx.sh` runs `envsubst '$DOMAIN_NAME'` on it — only `$DOMAIN_NAME` is substituted; all other `$` references are nginx variables and must not use shell default syntax.

## Portainer notes

- Portainer data (users, settings, endpoints) persists in the `port_data` volume at `~/data/port`.
- The **initial admin account** must be created on first access. If the setup timeout is reached, restart the container: `docker restart portainer`.
- Port **9443** is published directly to the host for HTTPS access without going through NGINX.
- Port **8000** (Edge agent tunnel) is not used and not exposed.
- The `--no-analytics` flag disables Portainer telemetry.

## FTP notes

- The FTP user is created with UID/GID matching `www-data` (33) so it has the same filesystem permissions as PHP-FPM in the WordPress container.
- **`FTP_PASV_ADDRESS`** in `srcs/.env` must be set to the VM's IP address for passive mode to work from an external client.
- Only one passive port is used (`PASV_MIN_PORT=PASV_MAX_PORT=21100`) to keep the port-forwarding setup simple.

## Web (Next.js) notes

- Built from the `tools/site/` directory, which is the Next.js app source.
- Dependencies are installed at **image build time** (`RUN npm install`) so the container starts immediately.
- The dev server (`next dev --turbopack`) runs inside the container. WebSocket connections for HMR are proxied by NGINX with the `Upgrade` and `Connection` headers.
- Node.js 22 LTS is installed via the NodeSource apt repository (not Debian's default `nodejs` package, which is older and slower to install due to its large dependency tree).
